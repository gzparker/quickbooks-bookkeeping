# quickbooks-bookkeeping

> **DECOMMISSIONED (2026-08-19):** The hosted QuickBooks Online MCP was removed
> from the Hetzner orchestrator — it was decided to be the wrong tool.
> Bookkeeping is now done directly in the QuickBooks Online UI. This repo is
> kept for accounting notes and history; AdLoop and every other service on the
> box are unaffected. See `NOTES.md` for details. The text below is historical.

Read-only QuickBooks Online access for Cursor (IDE and cloud agents), via
Intuit's official MCP server hosted on the Hetzner orchestrator box.

This is a Cursor workspace: open it in Cursor and the assistant can query the
books directly. It is also the deployment record for the server itself — the
systemd unit, the tunnel ingress stanza, and the runbook all live here.

Built to mirror the AdLoop MCP deployment (`gzparker/online-va-team-ads`)
hostname for hostname and flag for flag.

> **This repo is public.** No client secret, refresh token, realm id, or
> Cloudflare Access service token belongs in any file here.

---

## Status: prepared, NOT yet live

Everything that can be automated is done. The server is installed and built on
the box; nothing is running and nothing public is exposed yet, because the
remaining steps need a human with Intuit and Cloudflare dashboard access.

| | State |
|---|---|
| Upstream cloned + built on the box (`~/qbo-mcp-server`, pinned) | Done |
| Config / token store created (`~/.qbo/tokens.env`, 0600) | Done |
| Read-only enforcement verified empirically (71 tools, 0 mutating) | Done |
| Port 8091 confirmed free | Done |
| systemd unit written | Prepared, **not installed** |
| Tunnel ingress stanza written | Prepared, **not applied** |
| Intuit OAuth app + refresh token | **Human required** |
| Cloudflare Access app + service token + CORS | **Human required** |
| DNS record for `qbo.webpixelpro.com` | **Human required** |

Nothing on the box was restarted, reconfigured, or otherwise disturbed. AdLoop
and every `deerflow-*` unit were left exactly as found.

---

## What's inside

| File | Purpose |
|---|---|
| `RUNBOOK.md` | Install, config, service management, tunnel changes, troubleshooting, token renewal |
| `AGENTS.md` | Brief for any AI agent opening this workspace — what it can do and the read-only rule |
| `.cursor/rules/qbo.mdc` | Tool-level orchestration rules (Cursor auto-loads) |
| `.cursor/mcp.json.example` | MCP config template — copy to `.cursor/mcp.json` and paste the service token |
| `systemd/deerflow-qbo-mcp.service` | The unit file, to be copied to `/etc/systemd/system/` |
| `cloudflared/ingress-qbo.yaml` | The ingress stanza to add to `~/.cloudflared/config.yml`, shown in context |

## Wiring diagram

```
You (Cursor IDE or cloud agent)
        |
        | HTTPS (CF-Access-Client-Id / Secret headers)
        v
qbo.webpixelpro.com   -- Cloudflare Access gate (service token policy + CORS)
        |
        | Cloudflare Tunnel (shared with adloop / ai-admin / regen / persona-admin)
        v
Hetzner box   --- mcp-proxy :8091 --- Intuit QBO MCP server (stdio, Node 22)
                                        |
                                        +-- QuickBooks Online API (read-only)
```

## Operating principles

- **Read-only by construction.** The server starts with
  `QUICKBOOKS_DISABLE_WRITE`, `QUICKBOOKS_DISABLE_UPDATE` and
  `QUICKBOOKS_DISABLE_DELETE` all `true`. Of the 142 tools upstream ships, the
  71 `create_*`/`update_*`/`delete_*` tools are never registered; 71 read tools
  remain. Verified on the box, not assumed — see `RUNBOOK.md`.
- **The tunnel is the only ingress.** The daemon binds `127.0.0.1:8091`. No
  firewall change, no exposed port.
- **Cloudflare Access is the only authentication.** There is no app-level auth,
  so the Access policy is load-bearing. Do not add the hostname to the tunnel
  before the Access application exists.
- **Secrets live on the box.** `~/.qbo/tokens.env`, mode 0600, outside the git
  checkout so token rotation never collides with a `git pull`.

---

## Setup on a new workstation

```bash
git clone https://github.com/gzparker/quickbooks-bookkeeping.git
cd quickbooks-bookkeeping

# Copy the MCP config template, then paste the real service token into it.
cp .cursor/mcp.json.example .cursor/mcp.json
# Edit .cursor/mcp.json — replace the two <paste-...-here> placeholders.

cursor .
```

## Setup for Cursor cloud Background Agents

1. Create a Background Agent for this workspace in Cursor's dashboard.
2. Add environment variables `CF_ACCESS_CLIENT_ID` and `CF_ACCESS_CLIENT_SECRET`.
3. Switch the two header values in `.cursor/mcp.json` to `${CF_ACCESS_CLIENT_ID}`
   and `${CF_ACCESS_CLIENT_SECRET}`.
4. Cloud agents **must** use the `/mcp` endpoint — they don't support SSE.

---

## Remaining human checklist

These cannot be automated. Do them in order; steps 1–2 and 3–5 are independent
of each other, but the tunnel hostname (step 6) should go last.

### 1. Register the Intuit app

1. Sign in at [developer.intuit.com](https://developer.intuit.com) → **My Apps**
   → create an app, scope **`com.intuit.quickbooks.accounting`**.
2. Copy the **Client ID** and **Client Secret** for the environment you intend to
   use. Sandbox and production keys are separate and not interchangeable.
3. Add a **Redirect URI** under Keys & credentials:
   - Production requires a public HTTPS URI — use
     `https://qbo.webpixelpro.com/callback`.
   - Sandbox accepts `http://localhost:8000/callback`, which is easier for a
     first end-to-end test.
4. The redirect URI must match `QUICKBOOKS_REDIRECT_URI` in `~/.qbo/tokens.env`
   **byte for byte** — a trailing slash difference is enough to fail the
   handshake.

### 2. Run the one-time OAuth handshake

Yields the **refresh token** and **realm ID** (the company file id). On the box:

```bash
cd ~/qbo-mcp-server
# Put CLIENT_ID / CLIENT_SECRET / REDIRECT_URI / ENVIRONMENT into the token
# store first (chmod 600 ~/.qbo/tokens.env), then:
QUICKBOOKS_TOKEN_STORE_PATH=~/.qbo/tokens.env npm run auth
```

Follow the printed URL, authorise the company, and let it write
`QUICKBOOKS_REFRESH_TOKEN` and `QUICKBOOKS_REALM_ID` back into the token store.
Confirm both keys are present (`grep -c REFRESH_TOKEN ~/.qbo/tokens.env`) —
**do not print the values**.

> The handshake opens a browser and a local listener, so it's easiest run from a
> desktop with a browser. If running it headless over SSH, forward the callback
> port (`ssh -L 8000:localhost:8000 ...`) and open the URL locally.

> **Set a calendar reminder now, ~60 days out.** Intuit refresh tokens rotate on
> use and expire after **~100 days of disuse**. This server only refreshes when
> someone queries it, so a quiet quarter silently kills the connection and the
> only fix is redoing this handshake. Running any read tool resets the clock.

### 3. Create the Cloudflare Access application

In **Zero Trust → Access → Applications → Add an application → Self-hosted**:

- Application domain: `qbo.webpixelpro.com`
- Policy: **Service Auth** action, matching a **service token** (create a new one
  named e.g. `qbo-mcp`, or reuse the AdLoop pattern).
- Save the token's Client ID and Client Secret straight into the operator's
  local `SECRETS.md` — the secret is shown exactly once.

### 4. Enable CORS on that Access application — do not skip this

**This is the step that cost significant time on AdLoop.** Cursor's Electron MCP
client sends a cross-origin `OPTIONS` preflight *without* credentials (per spec).
Cloudflare Access sees an unauthenticated `OPTIONS`, returns **403**, the browser
cancels the real `POST`, and Cursor reports the generic *"Server returned an
unexpected response. It may not be an MCP server."* The daemon log on the box
shows **no incoming request at all**, which sends you debugging the wrong layer.

In the application → **Edit → Settings → CORS settings**, set exactly:

| Setting | Value |
|---|---|
| Bypass options requests to origin | **OFF** |
| Access-Control-Allow-Credentials | **OFF** (required when origin is `*`) |
| Access-Control-Max-Age | **600** |
| Access-Control-Allow-Origin | Allow all origins |
| Access-Control-Allow-Methods | Allow all methods |
| Access-Control-Allow-Headers | Allow all HTTP headers |

Verify — the preflight must return **200**:

```bash
curl -i -X OPTIONS \
  -H 'Origin: https://cursor.com' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,cf-access-client-id,cf-access-client-secret' \
  https://qbo.webpixelpro.com/mcp
```

And the authenticated `initialize` must return **200 with `serverInfo`**:

```bash
curl -i -X POST \
  -H 'CF-Access-Client-Id: <service token Client ID>' \
  -H 'CF-Access-Client-Secret: <service token Client Secret>' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"0.1"}}}' \
  https://qbo.webpixelpro.com/mcp
```

With both returning 200, Cursor's "Add Custom MCP" form will connect.

### 5. Put the service token in Cursor as **Headers**

In Cursor's MCP dialog, the "Client ID" and "Client Secret" fields are for **MCP
OAuth flows** and silently do nothing for Cloudflare Access. The service token
must go in **Headers** rows:

| Header | Value |
|---|---|
| `CF-Access-Client-Id` | `<service token Client ID>` |
| `CF-Access-Client-Secret` | `<service token Client Secret>` |

### 6. Install the unit and publish the hostname

Full commands, including the mandatory `cloudflared tunnel ingress validate`
before any reload, are in `RUNBOOK.md`. In short:

1. `sudo cp systemd/deerflow-qbo-mcp.service /etc/systemd/system/` →
   `daemon-reload` → `enable --now`, then confirm `127.0.0.1:8091` is listening
   and the read-only verify script reports 71 tools / 0 mutating.
2. Add the DNS CNAME for `qbo` → `<tunnel-uuid>.cfargotunnel.com` (proxied).
3. Back up `~/.cloudflared/config.yml`, insert the stanza from
   `cloudflared/ingress-qbo.yaml` above the `http_status:404` catch-all,
   **validate**, then restart `cloudflared`.

The tunnel config is shared with AdLoop and the admin UIs. A malformed edit
takes every hostname down, so the backup and the validate step are not optional.

---

## Related

- **AdLoop MCP (the pattern this copies):** `gzparker/online-va-team-ads` —
  Google Ads + GA4, port 8090.
- **Orchestrator host repo:** `gzparker/deerflow-ai-webpixel-machine` — the box
  this runs on. Note that the AdLoop unit is *not* checked in there; see the PR
  description for details.
- **Upstream MCP server:** `github.com/intuit/quickbooks-online-mcp-server`.
