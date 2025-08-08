FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm
# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    nano \
    build-essential \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Set environment variables
ENV PYTHONPATH=/workspace
ENV PYTHONUNBUFFERED=1
