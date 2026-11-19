#!/bin/sh
# Railway wrapper for ntfy: private by default (deny-all), one admin user
# and one access token for Odysseus, everything on the /var/lib/ntfy volume.
set -e

: "${NTFY_ADMIN_USER:=admin}"
if [ -z "${NTFY_ADMIN_PASSWORD:-}" ]; then
    echo "railway-start: NTFY_ADMIN_PASSWORD is not set" >&2
    exit 1
fi

mkdir -p /var/lib/ntfy/attachments

HASH="$(printf '%s\n%s\n' "$NTFY_ADMIN_PASSWORD" "$NTFY_ADMIN_PASSWORD" | ntfy user hash 2>/dev/null | grep -o '\$2[aby]\$[^[:space:]]*' | tail -n 1)"
if [ -z "$HASH" ]; then
    echo "railway-start: could not hash NTFY_ADMIN_PASSWORD" >&2
    exit 1
fi

export NTFY_AUTH_USERS="${NTFY_ADMIN_USER}:${HASH}:admin"
if [ -n "${NTFY_ODYSSEUS_TOKEN:-}" ]; then
    export NTFY_AUTH_TOKENS="${NTFY_ADMIN_USER}:${NTFY_ODYSSEUS_TOKEN}:Odysseus"
fi

export NTFY_LISTEN_HTTP=":${PORT:-8080}"
export NTFY_BEHIND_PROXY=true
export NTFY_CACHE_FILE=/var/lib/ntfy/cache.db
export NTFY_AUTH_FILE=/var/lib/ntfy/user.db
export NTFY_AUTH_DEFAULT_ACCESS=deny-all
export NTFY_ENABLE_LOGIN=true
export NTFY_ATTACHMENT_CACHE_DIR=/var/lib/ntfy/attachments

exec ntfy serve
