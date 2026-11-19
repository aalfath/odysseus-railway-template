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
item = {
    "id": uuid.uuid4().hex[:12],
    "preset": "ntfy",
    "name": "ntfy",
    "description": "Bundled ntfy server (Railway template). Subscribe on your phone with the same server URL.",
    "base_url": os.environ["NTFY_URL"].rstrip("/"),
    "auth_type": "bearer",
    "auth_header": "",
    "auth_param": "",
    "api_key": os.environ["NTFY_TOKEN"],
    "enabled": True,
}
with open("/app/data/integrations.json", "w", encoding="utf-8") as f:
    json.dump([item], f, indent=2)
os.chmod("/app/data/integrations.json", 0o600)
print("railway-start: added the bundled ntfy integration")
PY
fi

# Upstream entrypoint: fixes volume ownership, runs first-time setup
# (creates the admin from ODYSSEUS_ADMIN_USER / ODYSSEUS_ADMIN_PASSWORD),
# then drops to the unprivileged user.
exec /usr/local/bin/entrypoint.sh uvicorn app:app --host 0.0.0.0 --port "${PORT:-7000}"
