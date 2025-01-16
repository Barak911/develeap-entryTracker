#!/bin/bash


# Define S3 bucket and .env file
s3_bucket_name="entytracker-cicd"


apt-get update

# Install prerequisites
apt-get install -y ca-certificates curl gnupg git

# Create directory for keyrings
install -m 0755 -d /etc/apt/keyrings

# Download and install Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin unzip

# Add ubuntu user to docker group to run docker without sudo
usermod -aG docker ubuntu

systemctl enable docker
systemctl start docker

mkdir -p /home/ubuntu/workspace

cd /home/ubuntu/workspace

# Clone repository
git clone https://github.com/Barak911/entryTracker_CICD.git

chown -R ubuntu:ubuntu /home/ubuntu/workspace

# INSTALL AWS CLI AND UNZIP
cd /home/ubuntu/
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip -u awscliv2.zip
sudo /home/ubuntu/aws/install

# Download .env from S3
echo "Downloading .env file from S3..."
aws s3 cp s3://$s3_bucket_name/.env /home/ubuntu/workspace/.env

# Verify .env download
if [ -f "/home/ubuntu/workspace/.env" ]; then
    echo ".env file downloaded successfully to /home/ubuntu/workspace/.env"
else
    echo "Failed to download .env file from S3."
    exit 1
fi

# Copy and overwrite .env to target directory
echo "Copying .env to the target directory..."
mkdir -p /home/ubuntu/workspace/entryTracker_CICD
cp -f /home/ubuntu/workspace/.env /home/ubuntu/workspace/entryTracker_CICD/.env

# Load environment variables
echo "Loading environment variables from .env..."
export $(grep -v '^#' /home/ubuntu/workspace/entryTracker_CICD/.env | xargs)

# Verify environment variables
echo "Environment variables loaded:"
env