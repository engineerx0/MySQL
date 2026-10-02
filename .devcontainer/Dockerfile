FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update \
    && apt-get install -y mysql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
