#!/bin/bash
# ============================================================
# FETS Actionables — deploy to fets.live/act
# Usage: upload index.html to /tmp on the VPS, then run:
#   bash deploy_act.sh
# Auto-detects the fets.live docroot across common setups
# (nginx, Apache, OpenLiteSpeed, CloudPanel, CyberPanel,
# HestiaCP). Only ever CREATES <docroot>/act/index.html —
# it never touches your existing site files.
# ============================================================
set -u
SRC="${1:-/tmp/index.html}"
DOMAIN=fets.live

if [ ! -f "$SRC" ]; then
  echo "✗ $SRC not found — upload index.html to /tmp first (scp index.html root@SERVER:/tmp/)"
  exit 1
fi

echo "— Looking for the $DOMAIN docroot…"
DOCROOT=""

# 1. Ask the web server configs directly
for CONF_DIR in /etc/nginx /etc/apache2 /etc/httpd /usr/local/lsws/conf; do
  [ -d "$CONF_DIR" ] || continue
  HIT=$(grep -rlE "server_name[^;]*$DOMAIN|ServerName +$DOMAIN|vhDomain +$DOMAIN" "$CONF_DIR" 2>/dev/null | head -1)
  if [ -n "$HIT" ]; then
    echo "  found vhost config: $HIT"
    ROOT=$(grep -oE '(root|DocumentRoot|vhRoot)[ \t]+[^;#]+' "$HIT" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"')
    [ -n "$ROOT" ] && [ -d "$ROOT" ] && DOCROOT="$ROOT" && break
  fi
done

# 2. Fall back to well-known panel layouts
if [ -z "$DOCROOT" ]; then
  for CAND in \
    /var/www/$DOMAIN/public_html /var/www/$DOMAIN/html /var/www/$DOMAIN/public /var/www/$DOMAIN \
    /home/$DOMAIN/public_html \
    /home/*/htdocs/$DOMAIN \
    /home/*/domains/$DOMAIN/public_html \
    /home/*/web/$DOMAIN/public_html \
    /var/www/html; do
    if [ -d "$CAND" ]; then DOCROOT="$CAND"; break; fi
  done
fi

if [ -z "$DOCROOT" ]; then
  echo "✗ Could not find the docroot automatically. Diagnostics to send back:"
  echo "--- running web servers ---"
  ss -tlpn 2>/dev/null | grep -E ':80 |:443 ' || true
  echo "--- possible site folders ---"
  ls -d /var/www/* /home/*/htdocs /home/*/domains/* /home/*/web/* 2>/dev/null || true
  exit 1
fi

echo "✓ docroot: $DOCROOT"
mkdir -p "$DOCROOT/act"
cp "$SRC" "$DOCROOT/act/index.html"

# match ownership/permissions to the parent site so the web server can read it
OWNER=$(stat -c '%U:%G' "$DOCROOT")
chown -R "$OWNER" "$DOCROOT/act"
chmod 755 "$DOCROOT/act"
chmod 644 "$DOCROOT/act/index.html"

echo "✓ deployed: $DOCROOT/act/index.html (owner $OWNER)"
echo ""
echo "🎉 Open https://$DOMAIN/act — the FETS Actionables app should load."
echo "   (If you get a 404 and the site runs through a proxy/app instead of"
echo "   static files, send me the diagnostics above and I'll adjust.)"
