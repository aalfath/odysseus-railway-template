# ChromaDB 1.5.9 (the version Odysseus pins upstream), official image.
FROM chromadb/chroma:1.5.9@sha256:1e0b73a187a28757c572acba508c46f48c9e8b0acaf5c20e6d95cdedce1acdf6

# Persist to the Railway volume at /data and listen on IPv4 and IPv6
# so the private network reaches it.
COPY config.yaml /config.yaml
ENV ANONYMIZED_TELEMETRY=FALSE
