#!/bin/bash
# Called by piavpn (PORT_SCRIPT) with the PIA forwarded port as $1.
#
# Runs inside piavpn's network namespace, which qBittorrent shares, so it talks
# to qBittorrent on localhost. Logs in with QBT_USER / QBT_PASS (piavpn env,
# from servarr/.env.enc), so qBittorrent's "Bypass authentication for clients
# on localhost" can stay OFF. Otherwise every container in this namespace
# (prowlarr, sonarr, radarr, sabnzbd, seerr, flaresolverr's browser) would get
# unauthenticated qBittorrent admin.
#
# Without QBT_USER/QBT_PASS it falls back to unauthenticated calls, which work
# only while the localhost bypass is still on.

port="$1"
QBT_URL="http://localhost:8090"
MAX_ATTEMPTS=30   # 30 x 10s = 5 min

cookies=$(mktemp)
trap 'rm -f "$cookies"' EXIT

echo "Setting qBittorrent listen port ($port)..."

# Wait for the WebUI. /api/v2/app/version answers 403 when not logged in,
# so check only that the server responds at all.
attempt=0
until curl --silent --max-time 10 --output /dev/null "$QBT_URL/"; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
    echo "ERROR: qBittorrent WebUI not reachable after $MAX_ATTEMPTS attempts" >&2
    exit 1
  fi
  sleep 10
done

if [ -n "$QBT_USER" ] && [ -n "$QBT_PASS" ]; then
  # Password goes in on stdin, not argv. A wrong password exits at once
  # instead of retrying, since qBittorrent bans an IP after repeated failures,
  # and here that IP is localhost.
  result=$(printf '%s' "$QBT_PASS" | curl --silent --max-time 10 \
    --cookie-jar "$cookies" \
    --data-urlencode "username=$QBT_USER" \
    --data-urlencode "password@-" \
    "$QBT_URL/api/v2/auth/login")
  if [ "$result" != "Ok." ]; then
    echo "ERROR: qBittorrent login failed for user '$QBT_USER' (response: ${result:-none})" >&2
    exit 1
  fi
else
  echo "WARNING: QBT_USER/QBT_PASS not set; relying on qBittorrent's localhost auth bypass" >&2
fi

if curl --silent --fail --max-time 10 \
  --cookie "$cookies" \
  --data 'json={"listen_port": '"$port"'}' \
  "$QBT_URL/api/v2/app/setPreferences"; then
  echo "qBittorrent port updated ($port)"
else
  echo "ERROR: failed to set qBittorrent listen port ($port)" \
       "(bad credentials, or localhost bypass off without QBT_USER/QBT_PASS?)" >&2
  exit 1
fi
