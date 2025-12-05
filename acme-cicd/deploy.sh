#!/bin/sh

# Change to parent directory
cd "$(dirname "$0")/.."

# Check if wget and unzip are installed, install if missing
if ! command -v wget >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
    echo "Installing wget and unzip..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y wget unzip
else
    echo "wget and unzip already installed"
fi

# Check if AWS SAM CLI is installed
if ! command -v sam >/dev/null 2>&1; then
    echo "Installing AWS SAM CLI..."
    # Download the AWS SAM CLI installer for Linux x86_64
    wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip

    # Unzip the installer
    unzip aws-sam-cli-linux-x86_64.zip -d sam-installation

    # Install AWS SAM CLI
    ./sam-installation/install

    # Clean up installation files
    rm -rf aws-sam-cli-linux-x86_64.zip aws-sam-cli-linux-x86_64.zip.sha256 sam-installation
else
    echo "AWS SAM CLI already installed"
fi

# Verify the installation
sam --version

# Check if AWS CLI is installed
if ! command -v aws >/dev/null 2>&1; then
    echo "Installing AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf awscliv2.zip aws
else
    echo "AWS CLI already installed"
fi
# Verify AWS CLI installation
aws --version

# Deploy the code using AWS SAM
sam deploy \
    --no-confirm-changeset --capabilities CAPABILITY_IAM \
    --stack-name url-shortener-stack \
    --parameter-overrides "$(cat sam-parameters.txt) ParameterKey=PersonalAcessToken,ParameterValue=${GITHUB_PAT}" \
    --region us-east-1 \
    --resolve-s3

# Retrieve the API Gateway endpoint URL and output as JSON
export AWS_REGION=us-east-1
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name url-shortener-stack \
    --query "Stacks[0].Outputs[?OutputKey=='VueAppAPIRoot'].OutputValue" \
    --output text)

echo "{\"url-shortener.api.endpoint\": \"$API_ENDPOINT\"}" | tee deployment_output.json
