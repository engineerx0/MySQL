# MySQL Development Environment in GitHub Codespaces

This repository provides a simple **MySQL 8.0 environment for learning and practicing SQL in GitHub Codespaces** using Docker Compose.

There is no application or backend server. The Codespace provides the terminal, MySQL command-line client, and VS Code MySQL extension; MySQL runs in its own container.

The environment starts with the MySQL `root` administrative account only. 

## What This Setup Provides

- MySQL 8.0 server
- Persistent MySQL data using a Docker named volume
- MySQL command-line client
- VS Code MySQL extension
- Root administrative access for initial setup
- Automatic MySQL startup when the Codespace starts

## Project Structure

```text
.devcontainer/
├── devcontainer.json
├── docker-compose.yml
└── Dockerfile
```

## 1. Create a GitHub Codespace

1. Open this GitHub repository.
2. Select **Code → Codespaces → Create codespace on main**.
3. Wait for the Codespace to open.
4. Open the integrated terminal using **Terminal → New Terminal**.

The repository is usually available at:

```text
/workspaces/your-repository-name
```

## 2. Development Container

The `.devcontainer/Dockerfile` installs the MySQL command-line client in the Codespace development container:

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update \
    && apt-get install -y mysql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

This installs the **MySQL client**, not the MySQL server. The server runs separately in the `db` container.

## 3. MySQL Configuration with Docker Compose

The `db` service in `.devcontainer/docker-compose.yml` should use the root password but omit `MYSQL_DATABASE`, `MYSQL_USER`, and `MYSQL_PASSWORD`:

```yaml
services:
  app:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile

    volumes:
      - ..:/workspaces/${localWorkspaceFolderBasename}:cached

    command: sleep infinity

    depends_on:
      db:
        condition: service_healthy

  db:
    image: mysql:8.0
    restart: unless-stopped

    environment:
      MYSQL_ROOT_PASSWORD: root_password

    volumes:
      - mysql-data:/var/lib/mysql

    healthcheck:
      test:
        [
          "CMD",
          "mysqladmin",
          "ping",
          "-h",
          "localhost",
          "-u",
          "root",
          "-proot_password"
        ]
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 20s

volumes:
  mysql-data:
```

### MySQL settings

| Setting | Value |
|---|---|
| MySQL version | `8.0` |
| Host from the Codespace | `db` |
| Port | `3306` |
| Administrative username | `root` |
| Root password | `root_password` |
| Initial practice database | None |
| Initial non-root user | None |
| Storage volume | `mysql-data` |

> `root_password` is a learning-environment example. Do not use this password for a production database.

### Why is the host `db`?

Docker Compose creates a network for the services. The MySQL service is named `db`, so the development container can reach it at `db:3306`.

Do not use `localhost` from the development container: there, `localhost` refers to the development container itself, not the MySQL server container.

## 4. Configure the Codespace

In `.devcontainer/devcontainer.json`, configure the development container and MySQL extension. For example:

```json
{
  "name": "MySQL Codespace",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "shutdownAction": "stopCompose",

  "postCreateCommand": "rm -f \"$(git rev-parse --git-path hooks/post-commit)\" \"$(git rev-parse --git-path hooks/pre-push)\" \"$(git rev-parse --git-path hooks/post-checkout)\" \"$(git rev-parse --git-path hooks/post-merge)\"",

  "customizations": {
    "vscode": {
      "extensions": [
        "cweijan.vscode-mysql-client2"
      ]
    }
  }
}
```

The `service` setting selects `app` as the Codespace development environment. MySQL runs separately in `db`.

## 5. Rebuild the Codespace

After changing the `.devcontainer` files:

1. Open the Command Palette (`Ctrl+Shift+P` on Windows/Linux or `Cmd+Shift+P` on macOS).
2. Search for **Codespaces: Rebuild Container**.
3. Select it and wait for the rebuild.

The rebuild builds the development container, installs the MySQL client and VS Code extension, and starts MySQL.

## 6. Verify the MySQL Client

Open a terminal and run:

```bash
mysql --version
```

You should see a MySQL client version. If `mysql: command not found` appears, rebuild the Codespace.

## 7. Connect to MySQL from the Terminal

Connect as the root administrative user:

```bash
mysql -h db -u root -p
```

When prompted, enter the root password configured in Compose (`root_password` in the example).

Because no default database is configured, the MySQL prompt opens without selecting a practice database. You should see:

```text
mysql>
```

## 8. Optional: Create a Practice Database and User Yourself

**Nothing in the Docker configuration creates `store_database` or `store_manager`.** These are example names only. This section is a manual exercise to do later, after connecting as `root` through the extension or terminal.

When you are ready, run:

```sql
CREATE DATABASE store_database;
```

Create a separate user for your practice database:

```sql
CREATE USER 'store_manager'@'%' IDENTIFIED BY 'manager_password';
```

Grant that user privileges on the practice database:

```sql
GRANT ALL PRIVILEGES ON store_database.* TO 'store_manager'@'%';
```

You can then select the database in the current root session:

```sql
USE store_database;
```

Verify the selected database:

```sql
SELECT DATABASE();
```

To leave the MySQL prompt:

```sql
exit;
```

These SQL statements are examples for a learning environment. Choose appropriate credentials and privileges for your own setup.

## 9. Connect Using the VS Code MySQL Extension

Open the **MySQL Client** extension in the VS Code activity bar and create a connection.

### Initial connection (root)

Use this connection to administer MySQL and create databases and users:

| Setting | Value |
|---|---|
| Connection name | `MySQL Local` |
| Host | `db` |
| Port | `3306` |
| Username | `root` |
| Password | `root_password` |
| Default database | Leave empty |

The host is `db`, not `localhost`, because the extension runs in the Codespace development container.

### Optional practice connection (only after you create the example user)

Only if you manually ran the SQL in the previous section, create another connection:

| Setting | Value |
|---|---|
| Connection name | `Store Database` |
| Host | `db` |
| Port | `3306` |
| Username | `store_manager` |
| Password | `manager_password` |
| Default database | `store_database` |

You can now use the extension's SQL editor to run queries, create tables, insert data, and practice SQL.

## 10. Example: Create a Test Table

In the repository we have MySQL/database/initial_database.sql which have some demo queries to populate the database.

If you are using `store_manager` user, after connecting to `store_database` as `store_manager`, run:

```sql
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, price)
VALUES
    ('Keyboard', 49.99),
    ('Mouse', 24.99),
    ('Monitor', 199.99);

SELECT * FROM products;
```

## 11. Database Persistence

MySQL data is stored in the named Docker volume:

```yaml
volumes:
  - mysql-data:/var/lib/mysql
```

The database files are stored separately from the MySQL container filesystem. Rebuilding the development container normally preserves databases, users, tables, and data in this volume.

> Rebuilding a container and deleting the database volume are different operations. Removing the volume deletes the data stored in it.

Only if you intentionally want to erase the existing database volume, run:

```bash
docker compose down -v
```

This deletes the Compose-managed volume and all database data in it. Do not run it if you need to keep your existing data.

## 12. MySQL Starts Automatically

When the Codespace starts, Docker Compose starts the `app` and `db` services. The health check helps ensure MySQL is ready before the dependent `app` service proceeds.

Connect from the terminal with:

```bash
mysql -h db -u root -p
```

## 13. Troubleshooting

### `mysql: command not found`

Check:

```bash
mysql --version
```

If unavailable, rebuild the Codespace. The MySQL client is installed by the `.devcontainer/Dockerfile`.

### `Can't connect to MySQL server`

Wait a few seconds after startup, then check that the MySQL service is running and connect using:

```text
Host: db
Port: 3306
```

Do not use `localhost` from the development container.

### `Access denied for user`

For the initial administrative connection, verify:

```text
Username: root
Password: the MYSQL_ROOT_PASSWORD value in docker-compose.yml
```

For the practice connection, verify that you created the user and granted it access to `store_database`.

If the root password in Compose was changed after the MySQL data volume was initialized, the existing MySQL account password does not automatically change. Use the password already configured in the database or reset it through MySQL administration.

### `Unknown MySQL server host 'db'`

Check that:

1. The MySQL service is named `db` in `docker-compose.yml`.
2. The Codespace uses the Compose configuration and was rebuilt after configuration changes.
3. The development container is attached to the same Compose network.

### The VS Code MySQL extension is missing

Search the Extensions panel for **MySQL Client** or rebuild the Codespace. The extension is configured in `.devcontainer/devcontainer.json` as `cweijan.vscode-mysql-client2`.

## Connection Summary

Initial administrative connection:

```text
Host:     db
Port:     3306
Username: root
Password: root_password
Database: leave empty
```

Terminal command:

```bash
mysql -h db -u root -p
```

Only after you manually create the example practice database and user, connect with:

```text
Host:     db
Port:     3306
Username: store_manager
Password: manager_password
Database: store_database
```

## Final Architecture

This setup intentionally contains no application server or backend.

```text
GitHub Codespace
│
├── app
│   ├── VS Code
│   ├── Terminal
│   ├── MySQL CLI
│   └── MySQL VS Code Extension
│
└── db
    └── MySQL 8.0
        └── mysql-data
            └── Persistent database storage
```

The environment provides a persistent MySQL server for learning and practicing SQL. You create your own practice databases and users when you are ready.
