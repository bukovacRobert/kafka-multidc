#!/usr/bin/env bash

set -e

CONNECT_URL=http://localhost:8083

echo "Checking Kafka Connect HTTP API..."
curl -sf $CONNECT_URL/ | jq '.version' >/dev/null
echo "Kafka Connect is ready!"

for f in debezium/connect/*.json; do
  name=$(jq -r '.name' "$f")
  echo
  echo "Registering connector: $name from $f"

  curl -s -X PUT \
    -H "Content-Type: application/json" \
    "$CONNECT_URL/connectors/$name/config" \
    -d @"$f" | jq .
done

echo
echo "=== All connectors registered ==="
