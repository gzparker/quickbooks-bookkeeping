# AGENTS.md — workspace brief for any AI agent that opens this repo

> **You are landing in this workspace to answer questions about the business's
> QuickBooks Online books.** Read this whole file first, then
> `.cursor/rules/quickbooks.mdc` (Cursor auto-loads it). Operational and
> deployment detail lives in `RUNBOOK.md` — you rarely need it.

## What this repo is

A **wiring-and-docs repo**, not an application. It holds the deployment
artifacts and operating guidance for a QuickBooks Online MCP server running on
the orchestrator host. The MCP server itself is upstream code
(`intuit/quickbooks-online-mcp-server`), pinned to a commit and deployed
unmodified. We did not write it and we do not fork it.

This mirrors how `online-va-team-ads` wires up AdLoop for Google Ads.

## The single most important fact

**This deployment is read-only.** The service sets `QUICKBOOKS_DISABLE_WRITE`,
`QUICKBOOKS_DISABLE_UPDATE`, and `QUICKBOOKS_DISABLE_DELETE`, so create, update,
and delete tools are never registered. You will not see them in your tool list.

This is deliberate, and not a bug to work around. Upstream has **no dry-run, no
preview, and no audit log** — unlike AdLoop, which enforces `require_dry_run`
and logs every mutation. Until the filtering gateway described below exists,
there is no safe way to let an agent write to a production general ledger.

If the operator asks you to change something in QuickBooks: explain precisely
what you would change and let them do it in the QuickBooks UI. Do not ask for
the flags to be relaxed.

## Scope boundaries

You are a **data-plane agent**, not an infrastructure-plane agent.

- **YES:** read-only programmatic access to QuickBooks Online — entities,
  searches, and the standard financial reports.
- **NO:** SSH to the orchestrator host, the Cloudflare dashboard, or the Intuit
  Developer portal. If something there needs touching, ESCALATE — say what you
  want done and let the operator or an infra-capable assistant do it.
- **If tools fail persistently** (3+ consecutive errors): stop, report the exact
  error, and stop. Do not spiral. The usual causes are all infra-plane and are
  listed under "Known infrastructure constraints" below.

## Known infrastructure constraints

Recognize these so you do not waste a session treating them as data problems.

- **Refresh token expiry (~100 days).** QuickBooks refresh tokens lapse, and the
  failure is silent until a call fails. Symptom: every tool returns an auth or
  token error at once. Fix is a human re-running the OAuth handshake.
- **Cloudflare Access CORS must stay enabled** on the `qbo.webpixelpro.com`
  application. Disabling it breaks Cursor Cloud Agent connections at the
  preflight stage. Symptom: a generic "Server returned an unexpected response"
  with **no request reaching the host**.
- **Cloud agents use `/mcp`, not `/sse`.** The local IDE accepts either, so a
  config that works on the desktop can still fail in the cloud.
- **Service-token auth uses headers** `CF-Access-Client-Id` and
  `CF-Access-Client-Secret`, in **Headers** rows — never Cursor's Client ID /
  Client Secret fields, which are for MCP OAuth and ignore them silently.

## What you have access to (MCP — `quickbooks`)

Upstream registers **142 tools** unflagged. With all three disable flags set you
get **71**, all read-only — 42 fetch/report tools and 29 searches. Verified by
listing the tool surface both ways against the pinned build; the mutating 71
(25 create, 26 update, 20 delete) are not registered at all.

The read half falls into four families:

| Family | Shape | Examples |
| --- | --- | --- |
| Reports | `get_*` | profit and loss, balance sheet, cash flow, trial balance, general ledger, aged receivables/payables, customer/vendor balances |
| Entity fetch | `get_*` by id | invoice, bill, customer, vendor, account, payment, journal entry |
| Search | `search_*` | invoices, bills, customers, vendors, accounts, payments, journal entries |
| Company | — | company info, preferences |

**71 tools is still a lot, and it is a known weakness.** Do not skim the whole
list every time. Reach for reports first — they answer most real questions in
one call — and drop to entity search only when you need row-level detail.

## How to work

1. **Start with a report, not a search.** "How did we do last quarter?" is a
   profit-and-loss call, not a sweep of every invoice. Reports are one call,
   pre-aggregated, and far cheaper than reconstructing totals yourself.
2. **Never do arithmetic QuickBooks can do.** If you find yourself summing
   invoice line items to get revenue, stop and pull the right report. Hand
   arithmetic over an entity list is how you produce numbers that disagree with
   the operator's own dashboard, which destroys trust in everything else you say.
3. **Always state the date range and basis you used.** Cash versus accrual
   changes the answer materially. If the operator did not specify, say which you
   used and offer the other.
4. **Quote figures exactly as returned.** Do not round silently or reformat
   currency. If a number looks wrong, say so and show your source rather than
   correcting it yourself.
5. **Say when you are unsure.** Bookkeeping questions have real answers. A
   confident wrong number is worse than "the data does not clearly show this."

## What NOT to do

1. **Do not attempt writes.** They are not registered. If you think you found a
   mutating tool, you are misreading the tool list — say so rather than trying it.
2. **Do not give tax or compliance advice.** You can report what the books say.
   You cannot tell the operator what is deductible or how to file. Route those
   to their accountant, explicitly.
3. **Do not treat QuickBooks as ground truth about the business.** It reflects
   what was entered. Uncategorized transactions, unreconciled accounts, and
   stale AR are common; flag them rather than reporting around them.
4. **Do not dump raw API payloads.** Summarize, then offer detail on request.
5. **Do not ask the operator for things the MCP can fetch.** Look up the account
   list rather than asking what accounts exist.

## Definition of done (per session)

A good session ends with a specific, sourced answer — the figure, the report it
came from, the date range, and the basis — or a clear statement of what is
missing and which call would close the gap.

A bad session is a wall of unlabelled numbers, or totals assembled by hand from
entity searches that quietly disagree with the books.

## Planned: the filtering gateway

Two known problems point at the same fix. The tool surface is too large, and
there is no safe write path. Both are solved by a small stdio shim sitting
between `mcp-proxy` and upstream, which would:

- Collapse the surface to roughly a dozen tools using enum dispatch — `qb_query`,
  `qb_search`, `qb_get_entity`, `qb_get_report`, `qb_describe_entity` — with
  schema disclosed on demand rather than up front.
- Re-introduce the AdLoop idiom for writes: `qb_draft_*` returning a `plan_id`
  and a before/after preview, then `qb_confirm_and_apply(plan_id, dry_run=True)`,
  with an audit log at `~/.qbo/audit.log`. Deletes stay unregistered regardless;
  QuickBooks voids cover the legitimate cases.

It is not built. Until it is, this stays read-only. If you are an agent asked to
build it, it belongs in this repo, and it must not require forking upstream.

## Where the wiring lives (FYI, you don't need to touch any of this)

- Daemon: `deerflow-qbo-mcp.service` on the Hetzner box, `127.0.0.1:8091`,
  bridged by `mcp-proxy`.
- Public URL: `https://qbo.webpixelpro.com/mcp`
- Auth: Cloudflare Access service token (in `.cursor/mcp.json`, gitignored).
- Install: `~/.local/share/qbo-mcp`. Token store: `~/.qbo/tokens.env`.
- Logs: `sudo journalctl -u deerflow-qbo-mcp.service -f --no-pager`

If tools start failing and the operator confirms the daemon is running, the
cause is almost always token expiry or the Access CORS setting. Escalate per
Scope boundaries; do not try to work around it from the data plane.
