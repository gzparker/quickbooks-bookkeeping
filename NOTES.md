# Notes

## 2026-08-19 — Hosted QuickBooks Online MCP removed

The hosted QuickBooks Online MCP was decided to be the wrong tool and was torn
off the Hetzner orchestrator box. Bookkeeping is now done directly in the
QuickBooks Online UI.

What was removed on the box (QBO-only):

- `deerflow-qbo-mcp.service` — stopped, disabled, unit file deleted, systemd
  reloaded. Port 8091 is free.
- The `qbo.webpixelpro.com` ingress stanza in the cloudflared tunnel config
  (the live `~/.cloudflared/config.yml` was backed up first, then cloudflared
  restarted). The catch-all `http_status:404` remains last.
- `~/qbo-mcp-server` (the Intuit clone) and `~/.qbo/` (config + tokens).

What was intentionally left untouched:

- AdLoop (`deerflow-adloop-mcp.service`, port 8090, `adloop.webpixelpro.com`)
  and every other `deerflow-*` service and ingress on the box.
- This GitHub repo, which is kept for accounting notes and history.

No secrets, keys, or tokens are recorded here — this repo is public.
