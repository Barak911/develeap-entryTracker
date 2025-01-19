#!/bin/bash

# Define variables
FLASK_URL="http://localhost:5000/"
MAX_RETRIES=15
RETRY_INTERVAL=10

# Function to check Flask app availability
check_flask_app() {
  echo "Checking Flask app availability at ${FLASK_URL}..."
  for i in $(seq 1 $MAX_RETRIES); do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $FLASK_URL)
    if [ "$RESPONSE" -eq 200 ]; then
      echo "Flask app is up and running!"
      return 0
    fi
    echo "Retry $i/$MAX_RETRIES: Flask app not ready. Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
  done
  echo "Error: Flask app did not become available within the expected time."
  return 1
}

# Function to check database connection via the '/' endpoint
check_database_connection() {
  echo "Checking database connectivity through Flask app..."
  for i in $(seq 1 $MAX_RETRIES); do
    RESPONSE=$(curl -s -o response.json -w "%{http_code}" $FLASK_URL)
    if [ "$RESPONSE" -eq 200 ] && grep -q "Data fetched successfully from the database" response.json; then
      echo "Database connection is healthy!"
      rm -f response.json
      return 0
    fi
    echo "Retry $i/$MAX_RETRIES: Database not ready. Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
  done
  echo "Error: Database connection did not become healthy within the expected time."
  return 1
}

# Run health checks
check_flask_app && check_database_connection
RESULT=$?

if [ $RESULT -ne 0 ]; then
  echo "Health checks failed."
  exit 1
else
  echo "All health checks passed successfully."
fi
