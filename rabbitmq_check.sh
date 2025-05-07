#!/bin/sh

# Default values
RABBITMQ_HOST="0.0.0.0"
RABBITMQ_PORT="15672"
RABBITMQ_USER="USER"
RABBITMQ_PASS="PASS"
MAX_RETRIES=3
SLEEP_INTERVAL=2

# Usage message
usage() {
  echo "Usage: $0 [-H host] [-P port] [-u user] [-p pass] [-r retries] [-s sleep_interval]"
  echo "  -H HOST         RabbitMQ host (default: 0.0.0.0)"
  echo "  -P PORT         RabbitMQ port (default: 15672)"
  echo "  -u USERNAME     RabbitMQ username (default: USER)"
  echo "  -p PASSWORD     RabbitMQ password (default: PASS)"
  echo "  -r RETRIES      Max number of retries (default: 3)"
  echo "  -s INTERVAL     Seconds between retries (default: 2)"
  exit 1
}

# Check for --help before getopts (sh doesn't support long options in getopts)
for arg in "$@"; do
  if [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
    usage
  fi
done

# Parse command-line options
while getopts "H:P:u:p:r:s:" opt; do
  case $opt in
    H) RABBITMQ_HOST="$OPTARG" ;;
    P) RABBITMQ_PORT="$OPTARG" ;;
    u) RABBITMQ_USER="$OPTARG" ;;
    p) RABBITMQ_PASS="$OPTARG" ;;
    r) MAX_RETRIES="$OPTARG" ;;
    s) SLEEP_INTERVAL="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

echo "Checking RabbitMQ health at http://${RABBITMQ_HOST}:${RABBITMQ_PORT}..."

i=1
while [ "$i" -le "$MAX_RETRIES" ]; do
  RESPONSE=$(curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" "http://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api/health/checks/alarms")
  STATUS=$(echo "$RESPONSE" | grep '"status":"ok"')

  if [ -n "$STATUS" ]; then
    echo "✅ RabbitMQ is OK"
    exit 0
  else
    echo "⏳ Attempt $i/$MAX_RETRIES: Couldn't connect to RabbitMQ"
    sleep "$SLEEP_INTERVAL"
  fi

  i=$((i + 1))
done

echo "❌ RabbitMQ health check failed after $MAX_RETRIES attempts"
exit 1

