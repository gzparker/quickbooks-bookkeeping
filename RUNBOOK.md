# RUNBOOK — QuickBooks Online MCP server

Operational guide for the read-only QuickBooks Online MCP server that fronts
`https://qbo.webpixelpro.com/mcp`.

This mirrors the AdLoop MCP deployment (`gzparker/online-va-team-ads`) hostname
for hostname and flag for flag. If something here is ambiguous, the AdLoop
setup on the same box is the reference implementation.

> **This repo is public.** No client secret, refresh token, realm id, or
> Cloudflare Access service token belongs in any file here. Secrets live in
> `~/.qbo/tokens.env` on the orchestrator box (mode 0600) and in the operator's
> local, gitignored `SECRETS.md`.

---

## Architecture

```
Cursor (IDE or cloud agent)
    |  HTTPS + CF-Access-Client-Id / CF-Access-Client-Secret headers
    v
qbo.webpixelpro.com   -- Cloudflare Access gate (service token policy + CORS)
    |  Cloudflare Tunnel (shared with adloop / ai-admin / regen / persona-admin)
    v
orchestrator box  -- mcp-proxy :8091 -- Intuit QBO MCP server (stdio, Node 22)
                                          |
                                          +-- QuickBooks Online API (read-only)
```

| Thing | Value |
|---|---|
| Host | Hetzner `deerflow-orchestrator` (Ubuntu 24.04), service user `aivirtualmachine` |
| Public hostname | `https://qbo.webpixelpro.com` |
| MCP endpoint | `/mcp` (Streamable HTTP). `/sse` also exists but cloud agents can't use it |
| Local bind | `127.0.0.1:8091` (never `0.0.0.0` — the tunnel is the only ingress) |
| systemd unit | `deerflow-qbo-mcp.service` |
| Install dir | `~/qbo-mcp-server` (git clone, pinned) |
| Upstream | `github.com/intuit/quickbooks-online-mcp-server` |
| Pinned commit | `c351dc011d9cb14b211857457085f7994d8b1e15` (2026-08-10) |
| Config + token store | `~/.qbo/tokens.env` (0600, dir 0700) |
| Logs | `sudo journalctl -u deerflow-qbo-mcp.service` |
| Tools exposed | 71, all read-only (`get_*`, `read_*`, `search_*`) |

Port 8091 was chosen because 8090 (AdLoop), 8081 (image-regen), 8082
(persona-admin), 2026 (admin UI), 2024/20241 (langgraph), 8001 (uvicorn) and
3000 (next-server) are already claimed on this box.

---

## Read-only guarantee, and the one way to break it

The server ships 142 tools. 71 of them are `create_*` / `update_*` /
`delete_*`. All three are suppressed by the `QUICKBOOKS_DISABLE_*` flags, which
leaves exactly 71 read tools.

**The flags only work if they reach the Node process.** `mcp-proxy` spawns its
stdio child with an *empty* base environment unless `--pass-environment` is
passed, so the flags must be supplied as `-e KEY VALUE` pairs on the mcp-proxy
command line — which is what the unit file does. Moving them into
`Environment=` lines would leave them visible to mcp-proxy and invisible to
Node, and the server would come up with all 142 tools registered and no error
anywhere in the log.

Verified empirically on the box before handover:

| Configuration | Tools exposed | Mutating tools |
|---|---|---|
| No flags (upstream default) | 142 | 71 |
| All three flags via `-e` | 71 | 0 |

Re-verify any time the unit is edited — see *Verify the read-only surface*
below. Note also that classification is purely by name prefix: if upstream ever
adds a mutating tool that is not named `create_*`/`update_*`/`delete_*`, these
flags will not catch it. Worth a glance at the upstream changelog before
bumping the pin.

---

## Install (already done — recorded for rebuilds)

Node 22.22.2 and npm 10.9.7 were already present system-wide; `mcp-proxy`
0.12.0 was already installed via pipx for AdLoop and is reused as-is. Nothing
new was installed system-wide.

```bash
PIN=c351dc011d9cb14b211857457085f7994d8b1e15

git clone https://github.com/intuit/quickbooks-online-mcp-server.git ~/qbo-mcp-server
cd ~/qbo-mcp-server
git checkout "$PIN"

# npm ci honours package-lock.json; the repo's "prepare" script runs the
# TypeScript build automatically, so this produces dist/ in one step.
npm ci

test -x dist/index.js && echo "build ok"

# Config + rotating-token store. The server rewrites this file when Intuit
# rotates the refresh token, so it must be writable and must live OUTSIDE the
# install dir (otherwise a git pull fights the token rotation).
mkdir -p ~/.qbo && chmod 700 ~/.qbo
touch ~/.qbo/tokens.env && chmod 600 ~/.qbo/tokens.env
```

Deliberately **not** done: no `.env` was created inside `~/qbo-mcp-server`.
`QUICKBOOKS_TOKEN_STORE_PATH` fully replaces it.

---

## Configure

`~/.qbo/tokens.env` is both the config file the server reads at startup and the
file it rewrites on token rotation. Populate it after the OAuth handshake:

```ini
QUICKBOOKS_CLIENT_ID=...
QUICKBOOKS_CLIENT_SECRET=...
QUICKBOOKS_REFRESH_TOKEN=...
QUICKBOOKS_REALM_ID=...
QUICKBOOKS_REDIRECT_URI=https://qbo.webpixelpro.com/callback
QUICKBOOKS_ENVIRONMENT=production
```

`QUICKBOOKS_TOKEN_STORE_PATH` must **not** be set in this file — the server
resolves it before dotenv runs, so it only takes effect from the process
environment. The unit file supplies it.

---

## Install the unit and start the service

```bash
sudo cp systemd/deerflow-qbo-mcp.service /etc/systemd/system/
sudo systemd-analyze verify /etc/systemd/system/deerflow-qbo-mcp.service
sudo systemctl daemon-reload
sudo systemctl enable --now deerflow-qbo-mcp.service
systemctl status deerflow-qbo-mcp.service --no-pager
```

Confirm it is listening locally and that nothing else moved:

```bash
ss -ltnp | grep 8091      # expect 127.0.0.1:8091
ss -ltnp | grep 8090      # AdLoop must still be up
```

### Verify the read-only surface

Run this against the local port after any unit change. It must print 71 tools
and zero mutating tools.

```bash
python3 - <<'PY'
import json, urllib.request
BASE = "http://127.0.0.1:8091/mcp"
def post(payload, sid=None):
    req = urllib.request.Request(BASE, data=json.dumps(payload).encode(), method="POST",
        headers={"Content-Type": "application/json",
                 "Accept": "application/json, text/event-stream",
                 **({"mcp-session-id": sid} if sid else {})})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.headers.get("mcp-session-id"), r.read().decode()
def parse(b):
    for line in b.splitlines():
        if line.startswith("data:"):
            return json.loads(line[5:].strip())
    return json.loads(b)
sid, body = post({"jsonrpc":"2.0","id":1,"method":"initialize","params":{
    "protocolVersion":"2024-11-05","capabilities":{},
    "clientInfo":{"name":"probe","version":"0.1"}}})
print("serverInfo:", parse(body)["result"]["serverInfo"])
post({"jsonrpc":"2.0","method":"notifications/initialized"}, sid)
_, body = post({"jsonrpc":"2.0","id":2,"method":"tools/list"}, sid)
tools = [t["name"] for t in parse(body)["result"]["tools"]]
bad = [t for t in tools if t.startswith(("create_","create-","update_","update-","delete_","delete-"))]
print(f"total={len(tools)} mutating={len(bad)} {bad[:5]}")
assert not bad, "READ-ONLY VIOLATION: mutating tools are registered"
print("read-only OK")
PY
```

---

## Publish the tunnel hostname

The tunnel config is shared by every `*.webpixelpro.com` hostname on the box.
A malformed edit takes down **all** of them, AdLoop included.

```bash
cd ~/.cloudflared

# 1. Back up, always.
cp config.yml "config.yml.bak.$(date +%Y%m%d-%H%M%S)"

# 2. Add the stanza from cloudflared/ingress-qbo.yaml, above the
#    http_status:404 catch-all. The catch-all must remain LAST.
#    (Edit by hand; there is no safe sed for this.)

# 3. Validate BEFORE reloading. Do not skip this. Note: --config is a global
#    flag and must come BEFORE the `ingress` subcommand, not after it — the
#    trailing form errors with "flag provided but not defined: -config".
cloudflared tunnel --config ~/.cloudflared/config.yml ingress validate

# 4. Confirm the new rule resolves to the right origin.
cloudflared tunnel --config ~/.cloudflared/config.yml ingress rule \
  https://qbo.webpixelpro.com/mcp

# 5. Only once validation passes:
sudo systemctl restart cloudflared
sudo systemctl status cloudflared --no-pager | head -20
```

Expect `Registered tunnel connection ... connections=4`. If cloudflared fails
to start, restore the backup and restart before debugging anything else:

```bash
cp ~/.cloudflared/config.yml.bak.<timestamp> ~/.cloudflared/config.yml
sudo systemctl restart cloudflared
```

DNS: `qbo` needs a proxied CNAME to `<tunnel-uuid>.cfargotunnel.com` in the
`webpixelpro.com` zone. `cloudflared tunnel route dns <tunnel> qbo.webpixelpro.com`
creates it, or add it by hand in the dashboard. Get the tunnel UUID from
`cloudflared tunnel list` or the orchestrator repo's `docs/cloudflare-tunnel.md`.

---

## Service management

```bash
sudo systemctl status  deerflow-qbo-mcp.service
sudo systemctl restart deerflow-qbo-mcp.service
sudo systemctl stop    deerflow-qbo-mcp.service
sudo journalctl -u deerflow-qbo-mcp.service -n 100 --no-pager
sudo journalctl -u deerflow-qbo-mcp.service -f
```

Restarting this unit does not touch AdLoop or any `deerflow-*` unit; they are
independent processes on independent ports. `cloudflared` does not need a
restart when this service restarts — only when the ingress file changes.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Cursor: *"Server returned an unexpected response. It may not be an MCP server."* | Almost always the Cloudflare Access CORS preflight returning 403. The tell is **no request in `journalctl`** — Cursor's probe never arrived. See the CORS section below. |
| Cursor connects but no tools | Credentials landed in Cursor's "Client ID"/"Client Secret" fields instead of **Headers**. Those fields are for MCP OAuth and do nothing here. |
| `403` from Cloudflare Access on authenticated calls | Service token expired or rotated. Reissue in Zero Trust and update `.cursor/mcp.json` / the cloud-agent env vars. |
| `502` / `530` from cloudflared | Daemon down or wrong port: `systemctl status deerflow-qbo-mcp.service`, then `ss -ltnp \| grep 8091`. |
| Unit fails instantly, log says *"Client ID, Client Secret and Redirect URI must be set"* | `~/.qbo/tokens.env` is empty/unpopulated, or `QUICKBOOKS_TOKEN_STORE_PATH` isn't reaching Node (check it's an `-e` pair, not an `Environment=` line). |
| Unit fails with *"must be an absolute path"* | `QUICKBOOKS_TOKEN_STORE_PATH` was given a relative path. |
| Tools error with `invalid_grant` / 401 from Intuit | Refresh token expired (see *Token renewal*). |
| Write tools appear in the tool list | The `-e` DISABLE flags aren't reaching Node. Re-read *Read-only guarantee* and re-run the verify script. |

Remote smoke test (needs the service token):

```bash
# Preflight — must be 200 once Access CORS is configured.
curl -i -X OPTIONS \
  -H 'Origin: https://cursor.com' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type,cf-access-client-id,cf-access-client-secret' \
  https://qbo.webpixelpro.com/mcp

# Authenticated initialize — must be 200 with serverInfo in the body.
curl -i -X POST \
  -H 'CF-Access-Client-Id: <service token Client ID>' \
  -H 'CF-Access-Client-Secret: <service token Client Secret>' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"0.1"}}}' \
  https://qbo.webpixelpro.com/mcp
```

---

## Token renewal

Intuit's refresh token **rotates on use** and the server persists each new
value back into `~/.qbo/tokens.env`. Two consequences:

1. Never hand-edit `tokens.env` while the service is running — you will race
   the rotation and can strand a stale token. Stop the unit, edit, start it.
2. A refresh token that goes unused expires after **~100 days**. This service
   only refreshes when someone actually queries it, so a quiet quarter silently
   kills the connection. Put a recurring calendar reminder at ~60 days to run
   any read tool (or the verify script above with real credentials), which
   rotates the token and resets the clock.

If the refresh token has already lapsed, there is no recovery from the server
side — redo the one-time OAuth handshake (see `AGENTS.md` → the human
checklist, or step 2 of the deployment checklist in the PR description):

```bash
sudo systemctl stop deerflow-qbo-mcp.service
cd ~/qbo-mcp-server
QUICKBOOKS_TOKEN_STORE_PATH=~/.qbo/tokens.env npm run auth
sudo systemctl start deerflow-qbo-mcp.service
```

---

## Upgrading the pin

```bash
cd ~/qbo-mcp-server
git fetch origin
git log --oneline HEAD..origin/main        # read the diff before trusting it
git checkout <new-sha>
npm ci
sudo systemctl restart deerflow-qbo-mcp.service
# then re-run the read-only verify script — new tools may not follow the
# create_/update_/delete_ naming the DISABLE flags rely on
```

Record the new SHA in this file's table. Roll back by checking out the old SHA
and re-running `npm ci`.
