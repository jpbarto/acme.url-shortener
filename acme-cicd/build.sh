#!/bin/sh

# Assumes a recent version of Ubuntu with python3, unzip, and wget pre-installed

# Download the AWS SAM CLI installer for Linux x86_64
wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip

# Unzip the installer
unzip aws-sam-cli-linux-x86_64.zip -d sam-installation

# Install AWS SAM CLI
./sam-installation/install

# Clean up installation files
rm -rf aws-sam-cli-linux-x86_64.zip aws-sam-cli-linux-x86_64.zip.sha256 sam-installation

# Verify the installation
sam --version

# Validate the SAM template
sam validate --lint

# Build the application
sam build --build-dir build_output --config-file samconfig.toml
