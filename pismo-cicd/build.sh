#!/bin/sh

# Assumes a recent version of Ubuntu
# Update package lists and update dependencies
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    python3-pip \
    python3-venv \
    unzip \
    wget

# Install the AWS SAM CLI v2
pip install aws-sam-cli

# Verify the installation
sam --version

# Validate the SAM template
sam validate --lint

# Build the application
sam build --build-dir build_output --config-file samconfig.toml
