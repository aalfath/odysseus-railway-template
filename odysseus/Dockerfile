# Odysseus 1.0.3 (stable `main` build 9d0d372), official multi-arch image.
FROM ghcr.io/odysseus-dev/odysseus:1.0.3-9d0d372@sha256:5117c5e07e5976095ce213e601277ff372e0387a67de34c5fd59a3de723e6113

COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
