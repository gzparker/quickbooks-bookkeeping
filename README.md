# quickbooks-bookkeeping

Read-only AI access to the business's **QuickBooks Online** books, via an MCP
server on the orchestrator host.

This is a **wiring-and-docs repo**, not an application. The MCP server itself is
upstream code ([`intuit/quickbooks-online-mcp-server`](https://github.com/intuit/quickbooks-online-mcp-server)),
pinned to a commit and deployed unmodified. What lives here is the deployment
artifacts and the operating guidance — the same shape as `online-va-team-ads`,
which wires up AdLoop for Google Ads.

## Quick start

1. **Open this folder in Cursor.**
2. Copy `.cursor/mcp.json.example` to `.cursor/mcp.json` and supply the
   Cloudflare Access service token.
3. Ask the AI panel a question about the books — *"what does the P&L look like
   for last quarter?"*
4. The assistant follows `AGENTS.md` and `.cursor/rules/quickbooks.mdc`:
   reports first, exact figures, date range and accounting basis always stated.

For cloud agents, `.cursor/mcp.json` is not read — add the server through the
MCP dropdown at [cursor.com/agents](https://cursor.com/agents) and set
`CF_ACCESS_CLIENT_ID` / `CF_ACCESS_CLIENT_SECRET` as agent environment variables.

## Read-only, deliberately

The service runs with `QUICKBOOKS_DISABLE_WRITE`, `QUICKBOOKS_DISABLE_UPDATE`,
and `QUICKBOOKS_DISABLE_DELETE` all set, so create, update, and delete tools are
never registered. Measured against the pinned build, that takes the surface from
**142 tools to 71** — 42 fetch/report plus 29 search, and zero mutating.

Upstream has **no dry-run, no preview, and no audit log** — unlike AdLoop, which
enforces `require_dry_run` and logs every mutation to `~/.adloop/audit.log`. The
QuickBooks flags are all-or-nothing, so clearing them would give any connected
agent unlogged authority over the general ledger. Reporting and Q&A are useful
on their own; writes wait for the gateway described in `AGENTS.md`.

## What's inside

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Workspace brief — scope boundaries, how to use the tools well, what not to do |
| `RUNBOOK.md` | Install, OAuth, service, tunnel, Access, troubleshooting, upgrades |
| `.cursor/rules/quickbooks.mdc` | Orchestration rules (auto-loaded by Cursor) |
| `.cursor/mcp.json.example` | MCP config template |
| `.cursor/mcp.json` | (gitignored) Live config with the Access service token |
| `deploy/install-qbo-mcp.sh` | Idempotent installer for the orchestrator host |
| `deploy/deerflow-qbo-mcp.service` | systemd unit template |
| `deploy/cloudflared-ingress.snippet.yml` | Tunnel ingress stanza to merge by hand |
| `deploy/qbo-mcp.env.example` | Template for `~/.qbo/tokens.env` |
| `SECRETS.md.example` | Template for the credentials reference |
| `SECRETS.md` | (gitignored) Filled-in credentials reference for new workstations |
| `docs/tool-surface-evaluation.md` | Measured tool surface, and why "reports first" |

## Wiring

```
You (Cursor IDE or cloud agent)
        │
        │ HTTPS (CF-Access-Client-Id / CF-Access-Client-Secret headers)
        ▼
qbo.webpixelpro.com   ── Cloudflare Access gate (service token policy)
        │
        │ Cloudflare Tunnel
        ▼
Hetzner box   ─── mcp-proxy 127.0.0.1:8091 ─── quickbooks-online-mcp-server (stdio)
                                                 │
                                                 └── QuickBooks Online REST API v3
```

Deliberately identical to AdLoop, one port over. Upstream is a stdio MCP server,
`mcp-proxy` bridges it to HTTP, the tunnel publishes it, Access guards it.

## Status

Deployment artifacts are written; the service is not yet live. Remaining steps
are in `RUNBOOK.md`, and the ones needing a human are:

- Register the Intuit app and complete the OAuth handshake (§2–3). Note the trap
  documented there: **Cloudflare Access blocks the OAuth callback**, because the
  browser Intuit redirects has no service token. Start on sandbox.
- Create the Access application and **enable CORS on it** (§6). Skipping this
  produces a generic "not an MCP server" error in Cursor with no request ever
  reaching the host.

## Related

- **Upstream MCP server:** [`intuit/quickbooks-online-mcp-server`](https://github.com/intuit/quickbooks-online-mcp-server)
  — pinned at `c351dc0`, Apache-2.0, early preview
- **AdLoop workspace (same pattern, Google Ads):** `gzparker/online-va-team-ads`
- **Orchestrator host repo:** `gzparker/deerflow-ai-webpixel-machine` — where the
  tunnel config and sibling systemd units live
