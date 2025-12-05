#!/bin/sh

# Assumes a recent version of Ubuntu
# Update package lists and install Python and AWS SAM CLI
sudo apt-get update
sudo apt-get install -y python3 python3-pip unzip
pip3 install aws-sam-cli

# Deploy the code using AWS SAM
sam deploy --config-file samconfig.toml \
    --no-confirm-changeset --capabilities CAPABILITY_IAM \
    --stack-name url-shortener-stack \
    --resolve-s3
