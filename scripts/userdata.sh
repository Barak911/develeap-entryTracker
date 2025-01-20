#!/bin/bash

# Redirect all output to a log file
exec > /tmp/userdata.log 2>&1

# Define S3 bucket and .env file
s3_bucket_name="entytracker-cicd"


# Update the package list
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

# docker compose up -d
cd /home/ubuntu/workspace/entryTracker_CICD/
docker compose up -d

# wait for containers to start
sleep 180

# Check if mysql-db is running
echo "Checking mysql-db container status..."
MYSQL_DB_STATUS=$(docker inspect -f {{.State.Running}} mysql-db)
if [ "$MYSQL_DB_STATUS" == "true" ]; then
  echo "mysql-db container is running."
else
  echo "Error: mysql-db container is not running."
  exit 1
fi

# Check if flask-app is running
echo "Checking flask-app container status..."
FLASK_APP_STATUS=$(docker inspect -f {{.State.Running}} flask-app)
if [ "$FLASK_APP_STATUS" == "true" ]; then
  echo "flask-app container is running."
else
  echo "Error: flask-app container is not running."
  exit 1
fi

# Capture the exit code
EXIT_CODE=$?
echo $EXIT_CODE > /tmp/userdata_exit_code.txt

# Exit with the same code
exit $EXIT_CODE
