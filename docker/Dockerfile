# PiFire for development: the simulated (prototype) platform, no grill hardware.
# One container runs what supervisor runs on a Pi: Redis, control.py and the web app.
# Build from the repo root: docker build -f docker/Dockerfile -t pifire:dev .
FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1

# The build packages are only for the Python modules without wheels (bluepy, netifaces).
RUN apt-get update \
    && apt-get install -y --no-install-recommends redis-server libglib2.0-0 git procps gcc libc6-dev make pkg-config libglib2.0-dev

WORKDIR /usr/local/bin/pifire
COPY auto-install/requirements.txt /tmp/requirements.txt

# Same modules as auto-install/install.sh on Debian 12, minus rpi.gpio (Pi only).
RUN pip install --no-cache-dir -r /tmp/requirements.txt eventlet "influxdb_client[ciso]==1.48.0" scikit-learn==1.4.2 supervisor \
    && apt-get purge -y --auto-remove gcc libc6-dev make pkg-config libglib2.0-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/requirements.txt

COPY . .
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/entrypoint.sh /usr/local/sbin/pifire-entrypoint
COPY docker/sudo /usr/local/bin/sudo

# Settings can name either venv layout (python_exec) and the app has no venv here, so point both at this Python.
# Everything worth keeping goes through symlinks into /data, and recipes/ seeds it on the first start.
RUN rm -rf docker \
    && chmod 755 /usr/local/sbin/pifire-entrypoint /usr/local/bin/sudo \
    && mkdir -p .venv/bin /data /usr/local/share/pifire \
    && ln -s /usr/local/bin/python .venv/bin/python \
    && ln -s /usr/local/bin/python3 .venv/bin/python3 \
    && ln -s .venv/bin bin \
    && mv recipes /usr/local/share/pifire/recipes \
    && rm -rf logs history backups \
    && for path in settings.json pelletdb.json push_devices.json history recipes backups logs; do ln -s "/data/$path" "$path"; done \
    && pip list --format=json > pip_list.json \
    && chown -R 10001:10001 . /data

USER 10001:10001
VOLUME /data
EXPOSE 8000 9001

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/', timeout=4)"]

ENTRYPOINT ["/usr/local/sbin/pifire-entrypoint"]
