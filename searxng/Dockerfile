# SearXNG 2026.10.24-ef0ec03da (the version Odysseus pins upstream), official image.
FROM searxng/searxng:2026.10.24-ef0ec03da@sha256:7c7cbe509429e82755104b2a95f52085a98633c95d53f44e4e905fa3a59f08c8

# Odysseus queries SearXNG's JSON API over the private network.
# The secret comes from SEARXNG_SECRET, so the service keeps no state.
COPY settings.yml /etc/searxng/settings.yml
ENV GRANIAN_PORT=8080
