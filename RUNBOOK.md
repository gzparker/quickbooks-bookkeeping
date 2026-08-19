# RUNBOOK — QuickBooks Online MCP server

Operational guide for the `quickbooks` MCP server on the orchestrator host
(Hetzner). It mirrors the AdLoop deployment: an upstream stdio MCP server,
bridged to HTTP by `mcp-proxy`, published through the Cloudflare Tunnel, gated
by a Cloudflare Access service token.

```
Cursor (IDE or cloud agent)
    |  HTTPS + CF-Access-Client-Id / CF-Access-Client-Secret headers
    v
qbo.webpixelpro.com   -- Cloudflare Access gate (service token policy)
    |  Cloudflare Tunnel
    v
Hetzner box  -- mcp-proxy 127.0.0.1:8091 -- quickbooks-online-mcp-server (stdio)
    |
    v
QuickBooks Online REST API v3
```

| Thing | Value |
| --- | --- |
| Public hostname | `qbo.webpixelpro.com` |
| MCP endpoint | `https://qbo.webpixelpro.com/mcp` (Streamable HTTP) |
| Local port | `127.0.0.1:8091` (AdLoop uses 8090) |
| systemd unit | `deerflow-qbo-mcp.service` |
| Install dir | `~/.local/share/qbo-mcp` |
| Token store | `~/.qbo/tokens.env` (chmod 600) |
| Upstream | `intuit/quickbooks-online-mcp-server` @ `c351dc011d9cb14b211857457085f7994d8b1e15` |
| Write access | **Disabled** — all three `QUICKBOOKS_DISABLE_*` flags set (142 tools → 71, zero mutating) |

---

## 1. Install (automated)

```bash
git clone https://github.com/gzparker/quickbooks-bookkeeping.git
cd quickbooks-bookkeeping
./deploy/install-qbo-mcp.sh
```

Idempotent, and it does not start anything. It verifies Node 20+, checks that
port 8091 is free, clones upstream at the pinned commit, builds `dist/index.js`,
and creates `~/.qbo/` with a seeded token template.

Upstream is not on npm — `@qboapi/qbo-mcp-server` 404s on the registry — so it
is installed from git at a pinned SHA. Bumping that SHA is a deliberate act;
see [Upgrading](#9-upgrading-upstream).

---

## 2. Register the Intuit app (human, one time)

1. Sign in at [developer.intuit.com](https://developer.intuit.com) and create an app
   with the **Accounting** scope (`com.intuit.quickbooks.accounting`).
2. Copy the **Client ID** and **Client Secret** from *Keys & Credentials*.
   Sandbox and production have separate credential pairs — do not mix them.
3. Register Redirect URIs. Sandbox accepts `http://localhost:8000/callback`;
   production requires a public HTTPS URL.

### Read this before choosing a production redirect URI

**Cloudflare Access will block the OAuth callback.** Intuit redirects the
operator's browser to your redirect URI, and that browser has no service token,
so Access intercepts it and serves a login page instead of the callback. The
handshake fails in a way that looks like an Intuit problem and is not.

Pick one of these deliberately:

- **Sandbox first (recommended).** Use `http://localhost:8000/callback` and run
  the handshake through an SSH tunnel (§3). Nothing touches Access. Validate the
  whole pipe on sandbox data before involving the real company.
- **Production via a temporary Access bypass.** Add a policy on the Access
  application with action **Bypass** scoped to the `/callback` path, complete the
  handshake, then **remove the bypass immediately**. Leaving it in place is
  harmless for `/callback` itself but easy to over-scope by accident.
- **Production via a separate hostname.** Route a second hostname with no Access
  application in front of it. Cleanest separation, one more DNS record to own.

---

## 3. Complete the OAuth handshake (human, one time)

The server ships an auth helper that starts a local listener and opens a browser.
The Hetzner box is headless, so forward the port and drive it from your machine:

```bash
# From your workstation:
ssh -L 8000:localhost:8000 deerflow-hetzner
```

Then, in that SSH session:

```bash
cd ~/.local/share/qbo-mcp
QUICKBOOKS_TOKEN_STORE_PATH=$HOME/.qbo/tokens.env npm run auth
```

Open the printed URL in your local browser, approve the connection, and let the
callback land on `http://localhost:8000/callback` through the forwarded port.

On success the server writes `QUICKBOOKS_REFRESH_TOKEN` and
`QUICKBOOKS_REALM_ID` into `~/.qbo/tokens.env`. Confirm both are populated:

```bash
grep -c 'REFRESH_TOKEN=.\+' ~/.qbo/tokens.env   # expect 1
```

`QUICKBOOKS_TOKEN_STORE_PATH` must be exported in the environment, not written
into the env file — the server resolves it before loading dotenv, so a value
inside the file is silently ignored.

---

## 4. Install the service

```bash
sed -e "s|__SERVICE_USER__|$USER|g" \
    -e "s|__HOME__|$HOME|g" \
    -e "s|__MCP_PROXY__|$(command -v mcp-proxy)|g" \
    deploy/deerflow-qbo-mcp.service | sudo tee /etc/systemd/system/deerflow-qbo-mcp.service

sudo systemctl daemon-reload
sudo systemctl enable --now deerflow-qbo-mcp.service
systemctl status deerflow-qbo-mcp.service --no-pager
```

Verify the `mcp-proxy` flags against the installed version and against how
`deerflow-adloop-mcp.service` invokes it — the CLI has changed its port and host
flags across releases, and the unit here is written for the current form.

Confirm it is listening and answering before going any further:

```bash
ss -ltnp | grep 8091

curl -s -X POST http://127.0.0.1:8091/mcp \
  -H 'Accept: application/json, text/event-stream' \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"0.1"}}}'
```

A `serverInfo` block in the response means the stdio bridge works. Everything
after this point is networking.

### Confirm the deployment really is read-only

Do not take the flags on faith — assert it against the running service:

```bash
curl -s -X POST http://127.0.0.1:8091/mcp \
  -H 'Accept: application/json, text/event-stream' \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' \
  | grep -o '"name":"[^"]*"' \
  | grep -cE '"(create|update|delete)[_-]'
```

**Expect `0`.** Anything else means a flag is missing from the unit and the
general ledger is writable. Stop and fix it before publishing the hostname.

For reference, on the pinned build the surface is 142 tools unflagged and 71
with all three flags set. Note that upstream registers tools under *both*
`create_x` and `create-x` spellings, which is why the pattern above matches both.

---

## 5. Publish through the tunnel

Back up first — a malformed ingress file takes down **every** hostname on this
tunnel, AdLoop and the admin UIs included.

```bash
cp ~/.cloudflared/config.yml ~/.cloudflared/config.yml.bak.$(date +%F-%H%M)
```

Add the stanza from `deploy/cloudflared-ingress.snippet.yml` **above** the
`http_status:404` catch-all, then validate before reloading:

```bash
cloudflared tunnel ingress validate
cloudflared tunnel ingress rule https://qbo.webpixelpro.com/mcp   # must match the new rule
sudo systemctl reload cloudflared
```

Create the DNS record, which points the hostname at the tunnel:

```bash
cloudflared tunnel route dns <TUNNEL-UUID> qbo.webpixelpro.com
```

---

## 6. Cloudflare Access

1. **Zero Trust → Access → Applications → Add an application** (Self-hosted),
   hostname `qbo.webpixelpro.com`.
2. Add a policy with action **Service Auth** and a service token. Reuse the
   AdLoop token or mint a dedicated one; dedicated is better, because revoking
   QuickBooks access then does not disturb AdLoop.
3. **Enable CORS on the application.** This is not optional and it is the step
   that wastes the most time when skipped.

| CORS setting | Value |
| --- | --- |
| Bypass options requests to origin | OFF |
| Access-Control-Allow-Credentials | OFF (required when origin is `*`) |
| Access-Control-Max-Age | 600 |
| Access-Control-Allow-Origin | Allow all origins |
| Access-Control-Allow-Methods | Allow all methods |
| Access-Control-Allow-Headers | Allow all http headers |

Cursor's Electron client makes a cross-origin fetch with custom headers, so the
browser sends an `OPTIONS` preflight first, **without credentials**, per spec.
Access sees an unauthenticated `OPTIONS`, returns 403, and the browser cancels
the real POST. Cursor reports the generic *"Server returned an unexpected
response. It may not be an MCP server."* and `journalctl` shows **no incoming
request at all** — the giveaway that the request never reached the box.

Verify both halves:

```bash
# Preflight — 403 before the CORS fix, 200 after.
curl -i -X OPTIONS \
  -H 'Origin: https://cursor.com' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,cf-access-client-id,cf-access-client-secret' \
  https://qbo.webpixelpro.com/mcp

# Authenticated initialize — 200 with serverInfo.
curl -i -X POST \
  -H "CF-Access-Client-Id: $CF_ACCESS_CLIENT_ID" \
  -H "CF-Access-Client-Secret: $CF_ACCESS_CLIENT_SECRET" \
  -H 'Accept: application/json, text/event-stream' \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"0.1"}}}' \
  https://qbo.webpixelpro.com/mcp
```

Both returning 200 means Cursor will connect.

---

## 7. Connect Cursor

**Desktop.** `cp .cursor/mcp.json.example .cursor/mcp.json`, then either paste
the service token values or export `CF_ACCESS_CLIENT_ID` and
`CF_ACCESS_CLIENT_SECRET` and keep the `${...}` form.

**Cloud agents.** Local `mcp.json` is not read. Add the server through the MCP
dropdown at [cursor.com/agents](https://cursor.com/agents), and set the two
credentials as agent environment variables. Note that secrets are injected when
an agent VM boots, so an agent already running when you add them will not see
them — start a fresh agent.

Two client-side traps, both surfacing as the same generic connection error:

- Use `/mcp`, not `/sse`. Cloud agents do not support SSE. The local IDE accepts
  either, so a config that works on the desktop can still fail in the cloud.
- Put the token in **Headers** rows. Cursor's *Client ID* and *Client Secret*
  fields are for MCP OAuth flows and ignore these values silently.

---

## 8. Troubleshooting

| Symptom | First check |
| --- | --- |
| "Server returned an unexpected response. It may not be an MCP server." | Almost always the Access CORS preflight. Run the `OPTIONS` curl in §6. If it returns 403, that is your answer. |
| 403 on authenticated calls | Service token expired or rotated. Re-issue in Zero Trust and update the client config. |
| 502 from cloudflared | Daemon down: `sudo systemctl status deerflow-qbo-mcp.service`, then `journalctl -u deerflow-qbo-mcp.service -n 100 --no-pager`. |
| 404 from the tunnel | Ingress rule missing, or placed below the catch-all. `cloudflared tunnel ingress rule https://qbo.webpixelpro.com/mcp` shows which rule wins. |
| Tools error with auth/token failures | Refresh token lapsed. Redo §3. |
| Service will not start, complains about client ID/secret | `~/.qbo/tokens.env` is empty or unreadable by the service user. |
| Rotated token not persisting | `QUICKBOOKS_TOKEN_STORE_PATH` not set in the unit, or `~/.qbo` not writable. Check `ReadWritePaths` if `ProtectSystem=strict` is on. |

Logs: `sudo journalctl -u deerflow-qbo-mcp.service -f --no-pager`

**Do not** debug this by restarting `cloudflared` repeatedly — that interrupts
AdLoop and the admin UIs on the same tunnel. Reload rather than restart, and
confirm the fault is actually tunnel-side first.

---

## 9. Upgrading upstream

```bash
cd ~/.local/share/qbo-mcp
git fetch origin && git log --oneline HEAD..origin/main    # review before moving
git checkout <new-sha> && npm ci && npm run build
sudo systemctl restart deerflow-qbo-mcp.service
```

Update `UPSTREAM_SHA` in `deploy/install-qbo-mcp.sh` and the table above in the
same commit, so the repo and the box never disagree about what is deployed.

Upstream is version 0.0.1 and labelled an early preview, with active community
PRs landing against `main`. Read the diff rather than tracking the branch.

---

## 10. Token renewal

QuickBooks refresh tokens lapse after roughly **100 days**, and the access token
lasts an hour. The refresh token also **rotates on every refresh**, which is why
the token store must stay writable — losing a rotation means a manual re-auth.

The failure is silent until a tool call fails, so set a calendar reminder at
~90 days. Renewal is §3 again. This is the same class of problem as AdLoop's
weekly Google OAuth expiry while its consent screen sits in Testing mode.

---

## 11. Enabling writes

The unit sets `QUICKBOOKS_DISABLE_WRITE`, `_UPDATE`, and `_DELETE` to `true`,
so create, update, and delete tools are never registered.

Think hard before relaxing this. AdLoop has a genuine safety story — dry-run by
default, a budget cap, and an audit log at `~/.adloop/audit.log`. **Upstream
QuickBooks has none of it**: no dry-run, no preview, no audit trail, and the
flags are all-or-nothing. Clearing them gives any connected agent unlogged
authority to mutate the general ledger.

The intended path is the filtering gateway described in `AGENTS.md` — a small
stdio shim between `mcp-proxy` and upstream that curates the tool surface and
adds AdLoop-style `draft` → `confirm_and_apply(dry_run=True)` with an audit log
at `~/.qbo/audit.log`. Build that before granting write access.
