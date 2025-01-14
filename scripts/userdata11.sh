#!/bin/bash


# Authenticate to Amazon ECR
REGION="ap-south-1"
ACCOUNT_ID="796973518097"
REPOSITORY="barak/entry_tracker"
TAG="latest"

# Redirect all output to a log file for debugging
exec > /var/log/user-data.log 2>&1

# INSTALL Docker and AWS CLI:


# Update system and install Docker
apt update -y;
apt install -y docker.io;

# Start and enable Docker
systemctl start docker;
systemctl enable docker;

# To allow the default ec2-user to run Docker commands without sudo:
usermod -aG docker ubuntu

# Install Docker-compose
#apt install -y docker-compose;

# Verify Docker installation
docker --version || { echo "Docker installation failed"; exit 1; }

# Install AWS CLI
snap install core;
snap install aws-cli --classic;
aws --version || { echo "aws-cli installation failed"; exit 1; }


# Authenticate to Amazon ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Pull the Docker image
docker pull $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY:$TAG
#docker run -d -p 8080:80 796973518097.dkr.ecr.ap-south-1.amazonaws.com/barak/entry_tracker:latest

# Download docker-compose and dockerfile from github repository
cd /home/ubuntu/
git clone https://github.com/Barak911/develeap-entryTracker.git

# Run docker-compose up and use the pulled image
cd develeap-entryTracker
docker compose up -d