#!/bin/sh

# Change to parent directory
cd "$(dirname "$0")/.."

# Install wget and unzip non-interactively
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y wget unzip

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

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws
# Verify AWS CLI installation
aws --version

# Deploy the code using AWS SAM
sam deploy --config-file samconfig.toml \
    --no-confirm-changeset --capabilities CAPABILITY_IAM \
    --stack-name url-shortener-stack \
    --resolve-s3
