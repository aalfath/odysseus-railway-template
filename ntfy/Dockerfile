# ntfy v2.38.1, official image.
FROM binwiederhier/ntfy:v2.38.1@sha256:038da2be5e668fee6d36a62884eea48975e1b71c29a56964e5298c1b9165a573

COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
