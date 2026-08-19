#!/usr/bin/env bash
#
# Install the QuickBooks Online MCP server on the orchestrator host.
#
# Idempotent: safe to re-run. Installs and builds only; it never starts the
# service, because the server cannot run until the one-time Intuit OAuth
# handshake has produced a refresh token. See RUNBOOK.md.
#
# This script deliberately touches nothing outside $QBO_HOME and the install
# directory. It does not modify cloudflared, systemd, or any existing service.

set -euo pipefail

# Resolved before any cd, so later steps can still find files shipped alongside
# this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Upstream is not published to npm, so it is installed from git at a pinned
# commit rather than a version range.
UPSTREAM_REPO="https://github.com/intuit/quickbooks-online-mcp-server.git"
UPSTREAM_SHA="c351dc011d9cb14b211857457085f7994d8b1e15"

INSTALL_DIR="${QBO_INSTALL_DIR:-$HOME/.local/share/qbo-mcp}"
QBO_HOME="${QBO_HOME:-$HOME/.qbo}"
TOKEN_STORE="$QBO_HOME/tokens.env"
PORT="${QBO_PORT:-8091}"

log() { printf '\n=== %s\n' "$1"; }

log "Preflight"

if ! command -v node >/dev/null 2>&1; then
  cat >&2 <<'EOF'
ERROR: node is not installed or not on PATH.

Install Node 20+ (22 recommended) using whatever convention this host already
uses, then re-run. This script will not install a system-wide runtime on a
production box on your behalf.
EOF
  exit 1
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "ERROR: node $(node -v) is too old; upstream needs 20+ (22 recommended)." >&2
  exit 1
fi
echo "node $(node -v), npm $(npm -v)"

if ! command -v mcp-proxy >/dev/null 2>&1; then
  cat >&2 <<'EOF'
WARNING: mcp-proxy not found on PATH.

It bridges this stdio MCP server to HTTP, the same way it does for AdLoop.
If AdLoop runs it from a virtualenv or an absolute path, use that same path in
the systemd unit rather than installing a second copy.
EOF
fi

# A port collision would be silent until the service failed to bind, so check
# it here rather than at first start.
if command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q ":${PORT}\b"; then
  echo "ERROR: port ${PORT} is already in use. Pick another and set QBO_PORT." >&2
  ss -ltnp 2>/dev/null | grep ":${PORT}\b" >&2 || true
  exit 1
fi
echo "port ${PORT} is free"

log "Fetching upstream at ${UPSTREAM_SHA}"

if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" fetch --depth 50 origin
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$UPSTREAM_REPO" "$INSTALL_DIR"
fi

git -C "$INSTALL_DIR" checkout --quiet "$UPSTREAM_SHA"
echo "checked out $(git -C "$INSTALL_DIR" rev-parse --short HEAD)"

log "Building"

cd "$INSTALL_DIR"
npm ci --no-audit --no-fund 2>/dev/null || npm install --no-audit --no-fund
npm run build

if [ ! -f "$INSTALL_DIR/dist/index.js" ]; then
  echo "ERROR: build did not produce dist/index.js" >&2
  exit 1
fi
echo "built $INSTALL_DIR/dist/index.js"

log "Preparing token store"

# The refresh token rotates on every use and is the only thing standing between
# us and a manual browser re-auth, so the directory is owner-only.
mkdir -p "$QBO_HOME"
chmod 700 "$QBO_HOME"

if [ ! -f "$TOKEN_STORE" ]; then
  cp "$SCRIPT_DIR/qbo-mcp.env.example" "$TOKEN_STORE"
  echo "seeded $TOKEN_STORE from the template - fill in real values"
else
  echo "$TOKEN_STORE already exists, left untouched"
fi
chmod 600 "$TOKEN_STORE"

cat <<EOF

=== Installed, not started

  install dir   $INSTALL_DIR
  pinned commit $UPSTREAM_SHA
  token store   $TOKEN_STORE
  port          $PORT

Next, in order (see RUNBOOK.md):
  1. Register the Intuit app and complete the OAuth handshake.
  2. Fill in $TOKEN_STORE.
  3. Install the systemd unit and start the service.
  4. Add the cloudflared ingress rule and the Cloudflare Access application.
EOF
