for user in {1..10}; do
  echo "=== Testing user-$user ==="
  for req in {1..5}; do
    curl -X POST http://127.0.0.1/sms \
      -H "Content-Type: application/json" \
      -H "x-user-id: user-$user" \
      -d '{"sms": "Win free prize now!"}'
  done
  sleep 1
done