# AGENTS.md — workspace brief for any AI agent that opens this repo

> **You are landing in this workspace to answer questions about the books.**
> This workspace is wired to a QuickBooks Online MCP server. It is
> **read-only** — by construction, not by convention. Read this file before
> your first tool call.

## What this is

An MCP bridge to the operator's QuickBooks Online company file, hosted on the
same orchestrator box as the AdLoop (Google Ads) MCP server and gated the same
way. You get 71 read tools over the QuickBooks Online API.

| | |
|---|---|
| MCP server name | `quickbooks` |
| Endpoint | `https://qbo.webpixelpro.com/mcp` |
| Auth | Cloudflare Access service token, sent as HTTP headers |
| Upstream | Intuit's official `github.com/intuit/quickbooks-online-mcp-server` |
| Mode | Read-only — `create_*`, `update_*`, `delete_*` tools are not registered |

## Read-only means read-only

The server is started with `QUICKBOOKS_DISABLE_WRITE`,
`QUICKBOOKS_DISABLE_UPDATE` and `QUICKBOOKS_DISABLE_DELETE` all set to `true`.
The 71 mutating tools are never registered, so they do not appear in your tool
list and cannot be called.

**Do not try to work around this.** If the operator asks you to create an
invoice, void a transaction, reclassify an expense, or change anything at all in
QuickBooks:

1. Say plainly that this connection cannot write.
2. Describe the change you would make, precisely enough that the operator can
   do it in the QuickBooks UI in one pass.
3. Offer to verify the result afterwards with a read tool.

Enabling writes is an infrastructure change (a systemd unit edit plus a service
restart on a production box), not something to negotiate mid-conversation.

## What you can call

All tools are `get_*`, `read_*` or `search_*`. Broadly:

- **Reports** — `get_profit_and_loss`, `get_balance_sheet`, `get_cash_flow`,
  `get_general_ledger`, `get_trial_balance`, `get_aged_receivables`,
  `get_aged_payables`, `get_customer_balance`, `get_vendor_balance`,
  `get_customer_sales`, `get_vendor_expenses`.
- **Search across entities** — `search_invoices`, `search_bills`,
  `search_payments`, `search_customers`, `search_vendors`, `search_accounts`,
  `search_journal_entries`, `search_items`, `search_purchases`,
  `search_deposits`, `search_estimates`, `search_credit_memos`,
  `search_sales_receipts`, `search_transfers`, `search_budgets`, and more.
- **Fetch one record** — `get_invoice_pdf`, `get_customer`, `get_vendor`,
  `get_account`, `get_journal_entry`, `get_bill_payment`, `get_deposit`, etc.
- **Company context** — `get_company_info`, `get_preferences`.

Call `get_company_info` once at the start of a session to confirm the
connection is live and that you are pointed at the expected company file.

## How to work

1. **Confirm the period before you analyse it.** Fiscal year and accounting
   method (cash vs accrual) change every number. `get_preferences` and
   `get_company_info` tell you the setup; ask the operator if still ambiguous.
2. **Prefer reports over reconstruction.** If you want net income, call
   `get_profit_and_loss` — do not sum invoices and bills by hand. The report
   endpoints already apply QuickBooks' own logic for accruals, journal entries
   and adjustments; your reconstruction will disagree with what the operator
   sees in the UI, and the operator's UI is the source of truth.
3. **Search is paginated and date-bounded.** Pass explicit date ranges. An
   unbounded `search_*` on a mature company file returns a truncated window that
   looks complete and is not.
4. **Quote figures with their basis.** "Q2 net income was $X (accrual, per
   `get_profit_and_loss` for 2026-04-01..2026-06-30)" — not a bare number.
5. **Round-trip suspicious numbers.** If a total looks wrong, drill into the
   underlying transactions with a `search_*` call before calling it an error.
   Bookkeeping anomalies are usually classification, timing, or an
   unreconciled account — not a bug in the data.

## What NOT to do

1. **Do not give tax or legal advice.** You can report what the books say. You
   cannot conclude what is deductible, what the tax liability is, or how to
   structure anything. Point at the CPA.
2. **Do not assume the books are closed or reconciled.** Recent periods
   routinely contain uncategorised transactions and unreconciled accounts.
   Check before drawing conclusions from a current-month figure.
3. **Do not dump raw JSON at the operator.** Summarise, then offer the detail.
4. **Do not paste account numbers, full customer lists, or transaction dumps
   into files in this repo.** This repo is public.
5. **Do not attempt server-side fixes.** You have no SSH access to the
   orchestrator box, on purpose. See *Escalation*.

## Escalation

You are a **data-plane agent**, not an infrastructure-plane agent. You do not
have SSH to the orchestrator box, Intuit developer portal access, or Cloudflare
dashboard access.

If tool calls fail persistently (3+ consecutive errors), stop investigating the
data, report the exact error, and stop. Don't spiral. The likely causes all
need the operator:

- **`invalid_grant` / 401 from Intuit** — the refresh token expired. Needs a
  re-auth on the box. Refresh tokens also lapse after ~100 days of disuse.
- **403 from Cloudflare Access** — service token rotated or expired.
- **"Server returned an unexpected response. It may not be an MCP server."** —
  Cloudflare Access CORS preflight is failing. An infra fix, not a data problem.
- **502 / 530** — the daemon is down on the box.

Operational detail for all of these is in `RUNBOOK.md`. Read it to describe the
fix accurately; don't try to perform it.

## Where the wiring lives (FYI — you don't need to touch it)

- Daemon: `deerflow-qbo-mcp.service` on the Hetzner orchestrator, listening on
  `127.0.0.1:8091`, bridged by `mcp-proxy` (both `/sse` and `/mcp`).
- Public URL: `https://qbo.webpixelpro.com/mcp` (cloud agents need `/mcp`;
  they do not support SSE).
- Auth: Cloudflare Access service token in `.cursor/mcp.json` (gitignored).
- Install: `~/qbo-mcp-server`, pinned to commit
  `c351dc011d9cb14b211857457085f7994d8b1e15`. Config and rotating refresh token
  at `~/.qbo/tokens.env`.
- Sibling deployment using the identical pattern:
  `gzparker/online-va-team-ads` (AdLoop, Google Ads + GA4, port 8090).
