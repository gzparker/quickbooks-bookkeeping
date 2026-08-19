# QuickBooks (QBO) MCP — Cloudflare setup runbook

Hostname (confirmed by Greg): **`qbo.webpixelpro.com`**

This document describes the Cloudflare-only setup for the QuickBooks MCP endpoint and
records the current state. It intentionally contains **no secrets** — only names,
IDs, and the exact API calls needed to finish the job.

> Scope guardrails (do NOT violate):
> - Cloudflare only. Do **not** SSH into Hetzner, do **not** edit
>   `/home/aivirtualmachine/.cloudflared/config.yml`, do **not** start any QBO service.
> - A bad ingress stanza takes down AdLoop. The Hetzner steps below are documentation
>   for a human operator, not something this automation performs.

---

## Known-good facts (discovered)

| Item | Value |
| --- | --- |
| Cloudflare account | `91e81a21a580b172d8f95c68d190b2a1` ("Greg@parkerassetmanagement.com's Account") |
| Zone `webpixelpro.com` | `8fb29e3cd4eb04dcfdd541be11395100` (active, proxied plan) |
| Tunnel target (QBO) | `78ee7fdb-28db-411e-80f1-16b36e89a503.cfargotunnel.com` |
| Reference record | `adloop.webpixelpro.com` resolves to Cloudflare anycast (proxied / orange-cloud) — confirms the intended pattern for `qbo` |
| Zero Trust team | `remoteoperations.cloudflareaccess.com` |
| AdLoop MCP app AUD/kid | `4a31ebdf7f8d89d20a9f2289599112eb5e3e1e2faacc398820d04b51fa222a32` |
| Origin service (Hetzner) | `http://localhost:8091` (confirm port before wiring ingress) |

---

## BLOCKER — the available Cloudflare token is Workers-scoped only

The only Cloudflare credential present in this environment is the Cursor secret
**`CLOUDFLARE_WORKER_ACCESS_TOKEN`** (token id `3401d63848028efcd2b3005d556c2626`,
status active). Its effective permissions on the zone are exactly:

```
#zone_settings:edit, #zone_settings:read, #worker:edit, #worker:read, #zone:read
```

Empirically verified against the live API:

| Operation | Result |
| --- | --- |
| `GET /zones?name=webpixelpro.com` | OK (zone:read) |
| `GET /zones/{zone}/dns_records` | **Authentication error (10000)** |
| `POST /zones/{zone}/dns_records` (create `qbo`) | **Authentication error (10000)** |
| `POST /accounts/{acct}/access/service_tokens` | **auth.forbidden (1010)** |
| `POST /accounts/{acct}/access/apps` | **auth.forbidden (1010)** |

So the three mutating steps (DNS record, Access service token, Access app) **cannot be
performed with this token**. No other Cloudflare credential is present, and per the task
rules a new token must not be invented. A human with a properly scoped token (or the
Cloudflare dashboard) must run the steps below.

### Missing permissions to add to a token (or use dashboard)
- **DNS** → `DNS:Edit` for zone `webpixelpro.com`
- **Access: Service Tokens** → `Edit` on account `91e81a21a580b172d8f95c68d190b2a1`
- **Access: Apps and Policies** → `Edit` on the same account

---

## Step-by-step (run with a correctly-scoped token)

Set up shell variables first:

```bash
export CF_TOKEN='<token with DNS:Edit + Access edit>'
export ACCT='91e81a21a580b172d8f95c68d190b2a1'
export ZONE='8fb29e3cd4eb04dcfdd541be11395100'
export TUNNEL='78ee7fdb-28db-411e-80f1-16b36e89a503.cfargotunnel.com'
```

### 1. Confirm the AdLoop pattern, then create the proxied `qbo` CNAME

First read the live AdLoop record and copy its `content`/`proxied` shape (in case the
tunnel target differs from the value above):

```bash
curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records?name=adloop.webpixelpro.com" \
  -H "Authorization: Bearer $CF_TOKEN" | jq '.result[] | {name,type,content,proxied}'
```

Then create `qbo` as a **proxied (orange-cloud) CNAME** to the tunnel:

```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" \
  --data "{\"type\":\"CNAME\",\"name\":\"qbo\",\"content\":\"$TUNNEL\",\"proxied\":true,\"comment\":\"QuickBooks MCP tunnel\"}" \
  | jq '{id: .result.id, name: .result.name, content: .result.content, proxied: .result.proxied}'
```

Record the returned **DNS record id**.

### 2. Create the dedicated Access service token `qbo-mcp`

Do **not** reuse the AdLoop token.

```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCT/access/service_tokens" \
  -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" \
  --data '{"name":"qbo-mcp"}' \
  | jq '{id: .result.id, client_id: .result.client_id, client_secret: .result.client_secret}'
```

- `client_id` looks like `<uuid>.access` → goes in `CF-Access-Client-Id`.
- `client_secret` is shown **once** → goes in `CF-Access-Client-Secret`. Store it in the
  dashboard / a password manager; never commit it.

### 3. Create the self-hosted Access application `QBO MCP`

Domain may be the whole host (`qbo.webpixelpro.com`) or the path (`qbo.webpixelpro.com/mcp`).
The CORS block is **required** — without it Cursor reports "not an MCP server".

CORS spec (matches the required settings):
- Bypass OPTIONS to origin: **OFF** (`allow_all_origins`-style preflight handled by Access)
- Allow-Credentials: **OFF**
- Max-Age: **600**
- Allow-Origin: **all** (`*`)
- Allow-Methods: **all**
- Allow-Headers: **all** (must at least include `content-type`, `cf-access-client-id`, `cf-access-client-secret`)

```bash
SERVICE_TOKEN_ID='<id from step 2>'

curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCT/access/apps" \
  -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" \
  --data @- <<JSON | jq '{id: .result.aud, app_id: .result.id, domain: .result.domain}'
{
  "name": "QBO MCP",
  "domain": "qbo.webpixelpro.com/mcp",
  "type": "self_hosted",
  "session_duration": "24h",
  "cors_headers": {
    "allow_all_methods": true,
    "allow_all_headers": true,
    "allow_all_origins": true,
    "allow_credentials": false,
    "max_age": 600
  },
  "policies": [
    {
      "name": "Service Auth - qbo-mcp",
      "decision": "non_identity",
      "include": [ { "service_token": { "token_id": "'"$SERVICE_TOKEN_ID"'" } } ]
    }
  ]
}
JSON
```

> If the API rejects an inline `policies` array on create, create the app first, then
> `POST /accounts/$ACCT/access/apps/{app_id}/policies` with the same `decision`/`include`.
> Copy the live **AdLoop MCP** app's `cors_headers` verbatim if you can read it:
> `GET /accounts/$ACCT/access/apps` and find the app whose `aud` is
> `4a31ebdf7f8d89d20a9f2289599112eb5e3e1e2faacc398820d04b51fa222a32`.

Record the returned **Access app id** and **AUD**.

### 4. Verify the CORS preflight is 200 (not 403)

```bash
curl -s -o /dev/null -w "OPTIONS -> HTTP %{http_code}\n" -X OPTIONS \
  "https://qbo.webpixelpro.com/mcp" \
  -H "Origin: https://cursor.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type,cf-access-client-id,cf-access-client-secret"
```

Expected: **HTTP 200**. A `GET` may `302` to the Access login page until Hetzner ingress
exists — that is expected.

---

## Remaining box (Hetzner) steps — for a human operator, do NOT run from here

These are **not** performed by the Cloudflare automation. A bad ingress stanza takes down
AdLoop, so review carefully and confirm the origin port first.

1. **Confirm the QBO service port.** The assumed origin is `http://localhost:8091`.
   Verify the QBO MCP service is (or will be) listening there before touching ingress.
2. In `/home/aivirtualmachine/.cloudflared/config.yml`, add an ingress rule for
   `qbo.webpixelpro.com` **above** the final `404`/`http_status:404` catch-all:

   ```yaml
   ingress:
     # ... existing rules (e.g. adloop.webpixelpro.com) ...
     - hostname: qbo.webpixelpro.com
       service: http://localhost:8091
     # catch-all MUST remain last
     - service: http_status:404
   ```
3. Validate and reload cloudflared (e.g. `cloudflared tunnel ingress validate`, then the
   service reload appropriate to this host). Do not restart in a way that disrupts AdLoop.

---

## Current state (as recorded by the automation)

- Zone discovered: **yes** (`8fb29e3cd4eb04dcfdd541be11395100`).
- `qbo.webpixelpro.com` DNS record: **not created** (blocked — token lacks `DNS:Edit`).
- `qbo-mcp` service token: **not created** (blocked — `auth.forbidden`).
- `QBO MCP` Access app: **not created** (blocked — `auth.forbidden`).
- OPTIONS preflight: **HTTP 000 / does not resolve** (expected while the DNS record is absent).
