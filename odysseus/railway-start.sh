#!/bin/sh
# Railway wrapper for Odysseus: one volume at /app/data holds all state,
# the app listens on $PORT, and auth can't be switched off by accident.
set -e

DATA=/app/data
mkdir -p "$DATA/logs" "$DATA/ssh" "$DATA/huggingface" "$DATA/local" /app/.cache

# Railway gives a service one volume, so keep logs, the Cookbook SSH key,
# the HuggingFace cache and Cookbook-installed tools on it too.
link_into_volume() {
    src="$1"; dst="$2"
    if [ ! -L "$dst" ]; then
        [ -e "$dst" ] && rm -r "$dst"
        ln -s "$src" "$dst"
    fi
}
link_into_volume "$DATA/logs" /app/logs
link_into_volume "$DATA/ssh" /app/.ssh
link_into_volume "$DATA/huggingface" /app/.cache/huggingface
link_into_volume "$DATA/local" /app/.local

# Upstream's entrypoint only fixes ownership of the volume's top folder on
# Railway (it treats the mount as a broad host path), so hand the folders
# and files this script makes to the app user here.
APP_UID="${PUID:-1000}"; APP_GID="${PGID:-1000}"
fix_owner() { chown "$APP_UID:$APP_GID" "$@" 2>/dev/null || true; }
fix_owner "$DATA" "$DATA/logs" "$DATA/ssh" "$DATA/huggingface" "$DATA/local"

# Safe defaults for an internet-facing install.
export AUTH_ENABLED=true
export LOCALHOST_BYPASS=false
export SECURE_COOKIES="${SECURE_COOKIES:-true}"
export ODYSSEUS_ADMIN_USER="${ODYSSEUS_ADMIN_USER:-admin}"
export DATABASE_URL="${DATABASE_URL:-sqlite:////app/data/app.db}"

# Railway's public domain is the browser origin and the OAuth callback base.
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    export ALLOWED_ORIGINS="${ALLOWED_ORIGINS:-https://$RAILWAY_PUBLIC_DOMAIN}"
    export OAUTH_REDIRECT_BASE_URL="${OAUTH_REDIRECT_BASE_URL:-https://$RAILWAY_PUBLIC_DOMAIN}"
fi

# First boot only: wire the bundled ntfy server in as a notification
# integration (Settings > Integrations), with its access token.
if [ -n "${NTFY_URL:-}" ] && [ -n "${NTFY_TOKEN:-}" ] && [ ! -f "$DATA/integrations.json" ]; then
    python - <<'PY'
import json, os, uuid
token = os.environ["NTFY_TOKEN"]
if not token.startswith("tk_"):
    token = "tk_" + token
item = {
    "id": uuid.uuid4().hex[:12],
    "preset": "ntfy",
    "name": "ntfy",
    "description": "Bundled ntfy server (Railway template). Subscribe on your phone with the same server URL.",
    "base_url": os.environ["NTFY_URL"].rstrip("/"),
    "auth_type": "bearer",
    "auth_header": "",
    "auth_param": "",
    "api_key": token,
    "enabled": True,
}
with open("/app/data/integrations.json", "w", encoding="utf-8") as f:
    json.dump([item], f, indent=2)
os.chmod("/app/data/integrations.json", 0o600)
print("railway-start: added the bundled ntfy integration")
PY
fi
[ -f "$DATA/integrations.json" ] && fix_owner "$DATA/integrations.json"

# Upstream's compose starts the app after SearXNG and ChromaDB. On Railway
# all services start together, so wait (up to 3 minutes) until both answer;
# otherwise vector memory starts in a degraded mode.
python - <<'PY'
import os, socket, time
from urllib.parse import urlparse
targets = []
if os.getenv("CHROMADB_HOST"):
    targets.append(("ChromaDB", os.environ["CHROMADB_HOST"], int(os.getenv("CHROMADB_PORT") or 8000)))
u = urlparse(os.getenv("SEARXNG_INSTANCE") or "")
if u.hostname:
    targets.append(("SearXNG", u.hostname, u.port or 80))
deadline = time.time() + 180
for name, host, port in targets:
    while True:
        try:
            socket.create_connection((host, port), timeout=3).close()
            print(f"railway-start: {name} is up at {host}:{port}", flush=True)
            break
        except OSError:
            if time.time() > deadline:
                print(f"railway-start: {name} not reachable at {host}:{port}, starting anyway", flush=True)
                break
            time.sleep(3)
PY

# Upstream entrypoint: fixes volume ownership, runs first-time setup
# (creates the admin from ODYSSEUS_ADMIN_USER / ODYSSEUS_ADMIN_PASSWORD),
# then drops to the unprivileged user.
exec /usr/local/bin/entrypoint.sh uvicorn app:app --host 0.0.0.0 --port "${PORT:-7000}"
