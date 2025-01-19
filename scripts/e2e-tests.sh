#!/bin/bash

echo "Starting health checks..."

# Check Flask app
if curl -s http://localhost:5000/ > /dev/null; then
  echo "Flask app is running successfully!"
else
  echo "Flask app is not running!" >&2
  exit 1
fi

# Check MySQL
if mysqladmin ping -h 127.0.0.1 --silent; then
  echo "MySQL is running successfully!"
else
  echo "MySQL is not running!" >&2
  exit 1
fi

echo "All checks passed!"
