FROM mcr.microsoft.com/devcontainers/python:1-3.10-bookworm

# Install system dependencies for Frappe
RUN apt-get update && apt-get install -y \
    git curl wget nano build-essential \
    postgresql-client libpq-dev \
    xvfb libfontconfig \
    ca-certificates \
    libjpeg-dev zlib1g-dev libpng-dev libwebp-dev \
    libffi-dev libssl-dev \
    pkg-config \
    redis-tools \
    # For some reason, Frappe insists on having redis-server. Okay...
    redis-server \
    wkhtmltopdf \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18 + npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Optional: pipx for isolated bench installation
RUN python3 -m pip install --upgrade pip pipx && \
    python3 -m pipx ensurepath
ENV PATH=/root/.local/bin:$PATH

WORKDIR /workspace
ENV PYTHONPATH=/workspace
ENV PYTHONUNBUFFERED=1