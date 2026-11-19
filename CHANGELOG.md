# Changelog

## 1.0.3-9d0d372 (2026-11-19)

First release of the template.

- Odysseus 1.0.3, stable build `9d0d372` (`ghcr.io/odysseus-dev/odysseus@sha256:5117c5e07e5976095ce213e601277ff372e0387a67de34c5fd59a3de723e6113`).
- ChromaDB 1.5.9, SearXNG 2026.10.24-ef0ec03da, ntfy v2.38.1, each pinned by digest.
- All state on volumes: Odysseus `/app/data`, ChromaDB `/data`, ntfy `/var/lib/ntfy`.
- Generated admin password, SearXNG secret, ntfy admin password and ntfy access token. Auth is always on and the loopback bypass is forced off.
