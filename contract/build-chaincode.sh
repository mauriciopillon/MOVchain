#!/bin/bash

# Build script for your chaincode Docker image
set -e

echo "Building chaincode Docker image..."

# 1. Initialize go modules if not already done
if [ ! -f "go.mod" ]; then
    echo "Initializing go modules..."
    go mod init chaincode
fi

# 2. Download dependencies
echo "Downloading dependencies..."
go mod tidy

# 3. Build the Docker image
echo "Building Docker image..."
docker build -t mychaincode:latest .

# 4. Tag for local registry (if you're using one)
#echo "Tagging image for local registry..."
#docker tag mychaincode:latest mychaincode:latest

echo "Docker image built successfully!"
echo "Image: mychaincode:latest"
#echo "Registry image: localhost:5000/mychaincode:latest"
