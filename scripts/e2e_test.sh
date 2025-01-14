#!/bin/bash

# Cleanup function to ensure the Docker Compose stack is brought down
cleanup() {
  echo "Cleaning up Docker Compose stack..."
  docker compose down
}
trap cleanup EXIT

# Start Docker Compose
echo "Starting Docker Compose..."
docker compose up -d

# Wait for the application to be ready
echo "Waiting for the application to be ready..."
MAX_RETRIES=30
RETRY_INTERVAL=1
for i in $(seq 1 $MAX_RETRIES); do
  if curl -s http://localhost:5000 > /dev/null; then
    echo "Application is up and running!"
    break
  fi
  echo "Retry $i/$MAX_RETRIES: Application not ready yet. Retrying in $RETRY_INTERVAL second(s)..."
  sleep $RETRY_INTERVAL
done

# Check if the application failed to start
if ! curl -s http://localhost:5000 > /dev/null; then
  echo "Error: Application did not start within the expected time."
  docker compose logs
  exit 1
fi
