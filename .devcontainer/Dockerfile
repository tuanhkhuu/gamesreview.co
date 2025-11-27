FROM mcr.microsoft.com/devcontainers/ruby:1-3.3-bullseye

# Switch to root to install system packages
USER root

# Install Rails dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    postgresql-client \
    libpq-dev \
    build-essential \
    libssl-dev \
    libyaml-dev \
    libreadline-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm-dev \
    sqlite3 \
    libsqlite3-dev \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Switch back to vscode user
USER vscode

# Install Rails 8
RUN gem install rails -v '~> 8.0' && gem install bundler
