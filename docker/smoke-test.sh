#!/usr/bin/env bash
# Starts an image the way the stack does and checks that it works. Usage: docker/smoke-test.sh <image>
set -euo pipefail

image=$1
name=pifire-smoke
volume=pifire-smoke-data

cleanup() {
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker volume rm "$volume" >/dev/null 2>&1 || true
}
trap cleanup EXIT
cleanup

fail() {
  echo "FAIL: $1" >&2
  docker logs --tail 80 "$name" >&2 || true
  exit 1
}

start() {
  docker run -d --name "$name" --restart unless-stopped --cap-drop ALL --security-opt no-new-privileges:true \
    -e SUPERVISOR_PASSWORD=smoke -v "$volume:/data" "$image" >/dev/null
}

http_status() {
  docker exec "$name" python -c "import sys, urllib.request, urllib.error
try:
    print(urllib.request.urlopen('http://127.0.0.1:8000' + sys.argv[1], timeout=10).status)
except urllib.error.HTTPError as e:
    print(e.code)
except Exception:
    print('no response')" "$1"
}

# Waits for the web app to answer, then for both apps to be past supervisor's start window.
wait_ready() {
  for _ in $(seq 1 60); do
    if [ "$(http_status / 2>/dev/null)" = "200" ]; then
      sleep 5
      docker exec "$name" supervisorctl status && return 0
    fi
    sleep 2
  done
  fail "$1: the web app did not come up"
}

start
wait_ready "first start"

for page in / /dash /admin /settings /history /recipes /pellets /events /logs /update /api/current /mobile/v2/hello; do
  status=$(http_status "$page")
  echo "$page -> $status"
  case "$status" in
    2*) ;;
    *) fail "$page returned $status" ;;
  esac
done

docker exec "$name" test -s /data/settings.json || fail "settings.json is not in /data"
docker exec "$name" sh -c 'ls /data/recipes/*.pfrecipe >/dev/null' || fail "recipes were not seeded"

echo "--- files changed outside /data (anything worth keeping here would be lost on redeploy)"
docker diff "$name" | grep -vE ' /(tmp|data)(/|$)|__pycache__|\.pyc$' || true

echo "--- settings survive a new container"
docker exec "$name" sh -c 'python - <<EOF
import json
s = json.load(open("settings.json"))
s["globals"]["grill_name"] = "smoke test"
json.dump(s, open("settings.json", "w"))
EOF'
docker rm -f "$name" >/dev/null
start
wait_ready "new container"
docker exec "$name" grep -q '"grill_name": "smoke test"' /data/settings.json || fail "settings did not survive"

echo "--- restart through the sudo shim"
before=$(docker exec "$name" supervisorctl pid webapp)
docker exec "$name" sudo systemctl restart supervisor
sleep 15
after=$(docker exec "$name" supervisorctl pid webapp)
[ "$before" != "$after" ] || fail "the web app did not restart"
docker exec "$name" supervisorctl status || fail "not everything came back after the restart"

echo "--- reboot through the sudo shim"
count=$(docker inspect -f '{{.RestartCount}}' "$name")
docker exec "$name" sudo reboot || true
for _ in $(seq 1 40); do
  [ "$(docker inspect -f '{{.RestartCount}}' "$name")" != "$count" ] && break
  sleep 1
done
[ "$(docker inspect -f '{{.RestartCount}}' "$name")" != "$count" ] || fail "the container did not restart"
wait_ready "after reboot"

echo "PASS"
