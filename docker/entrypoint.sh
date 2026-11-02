#!/bin/sh
# Prepares /data, turns on the supervisor web UI if it has a password, then runs supervisor as PID 1.
set -e

if ! mkdir -p /data/history /data/backups /data/logs /data/recipes 2>/dev/null || [ ! -w /data/logs ]; then
  echo "/data is not writable by UID $(id -u). On the host: sudo chown -R 10001:10001 <data folder>" >&2
  exit 1
fi

# First start only, so recipes you delete stay deleted.
if [ ! -e /data/.recipes-seeded ]; then
  cp -an /usr/local/share/pifire/recipes/. /data/recipes/
  touch /data/.recipes-seeded
fi

mkdir -p /tmp/supervisor.d
if [ -n "${SUPERVISOR_PASSWORD:-}" ]; then
  umask 077
  cat > /tmp/supervisor.d/web-ui.conf <<EOF
[inet_http_server]
port = 0.0.0.0:9001
username = ${SUPERVISOR_USER:-admin}
password = ${SUPERVISOR_PASSWORD}
EOF
  umask 022
fi

exec supervisord -c /etc/supervisord.conf
