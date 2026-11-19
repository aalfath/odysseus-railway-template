[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/odysseus-2?utm_medium=integration&utm_source=button&utm_campaign=odysseus)

# Odysseus on Railway

One-click Railway template for [Odysseus](https://github.com/odysseus-dev/odysseus), the self-hosted AI workspace (chat, agents, deep research, notes, RAG). It deploys the full upstream stack as four services on Railway's private network:

| Service | Folder | Image (pinned by digest) | Volume | Public |
|---|---|---|---|---|
| Odysseus | `odysseus/` | `ghcr.io/odysseus-dev/odysseus:1.0.3-9d0d372` | `/app/data` (database, users, settings, uploads, logs, models cache) | yes, `/api/health` |
| ChromaDB | `chromadb/` | `chromadb/chroma:1.5.9` | `/data` (vector store for RAG and memory) | no |
| SearXNG | `searxng/` | `searxng/searxng:2026.10.24-ef0ec03da` | none (stateless, JSON API on) | no |
| ntfy | `ntfy/` | `binwiederhier/ntfy:v2.38.1` | `/var/lib/ntfy` (users, tokens, message cache) | yes, login required |

Each service builds from its folder's `Dockerfile`, which pins the official upstream image by version and digest and adds only a small start script or config file.

## Variables

Nothing to fill in. Railway generates every secret on deploy.

| Service | Variable | Value |
|---|---|---|
| Odysseus | `ODYSSEUS_ADMIN_USER` | `admin` |
| Odysseus | `ODYSSEUS_ADMIN_PASSWORD` | generated; read it in the service's Variables tab to log in |
| Odysseus | `ALLOWED_ORIGINS` | `https://` + the service's Railway domain |
| Odysseus | `CHROMADB_HOST`, `CHROMADB_PORT`, `SEARXNG_INSTANCE` | private-network references |
| Odysseus | `NTFY_URL`, `NTFY_TOKEN` | the bundled ntfy server and its access token (wired in as an integration on first boot) |
| ntfy | `NTFY_ADMIN_USER`, `NTFY_ADMIN_PASSWORD` | `admin` and a generated password |
| ntfy | `NTFY_ODYSSEUS_TOKEN` | generated access token used by Odysseus |
| SearXNG | `SEARXNG_SECRET` | generated |

The admin account is created once, on first boot. Changing `ODYSSEUS_ADMIN_PASSWORD` later doesn't change it: use the app's account settings.

LLM providers (OpenAI, Anthropic, OpenRouter, Ollama or any OpenAI-compatible endpoint) are added in the app under Settings after you log in.

## Updates

Railway tells everyone who deployed this template when `main` changes, and they choose when to apply it. Read `CHANGELOG.md` first: breaking changes are listed at the top of each entry. Data on the volumes is kept across updates.

## Local test

`docker compose -f compose.test.yml up --build` runs the same four services locally (Odysseus on http://localhost:7000).

## Licence

The template files in this repo are MIT. Odysseus is AGPL-3.0, ChromaDB is Apache-2.0, SearXNG is AGPL-3.0 and ntfy is Apache-2.0/GPL-2.0.
