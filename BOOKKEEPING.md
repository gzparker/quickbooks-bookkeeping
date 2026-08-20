# Bookkeeping working notes

## Working rules (hard rules — read first)

Greg's working method, recorded 2026-08-19. These govern everything else in this
repo. When in doubt, follow these over any inferred structure.

1. **Do not reinvent.** Last quarter is already reconciled and already labeled by
   the prior bookkeepers. **Do not recode, reopen, or restructure closed
   periods.**
2. **Document as you discover.** When you see how something was already coded or
   reconciled, write that rule into this repo (git) so we follow it next time.
   The repo is the **playbook, not a redesign.** Append newly observed rules to
   [`RULES.md`](RULES.md).
3. **Fiscal year starts January.** Last closed / reconciled quarter to assume:
   **Q2 2026 (Apr–Jun)** — unless QBO reconcile dates say otherwise. (A later
   pass will record the actual reconcile-through dates.)
4. **Current work is only activity after that close** (Q3 2026 onward) or items
   still pending that are clearly new. **Ask Greg before touching anything that
   might belong in a closed quarter.**
5. **Use the existing chart of accounts** (40s income / 50s COGS / 60s overhead)
   and the confirmed money flow in [`BANKS.md`](BANKS.md). [`ACCOUNTS.md`](ACCOUNTS.md)
   describes the file **as it is**, not a proposal.
6. **Kirk (Switzer Group) is the head accountant** — annual personal and
   business. **GATP** was the old quarterly bookkeeping team.
7. **Chrome: exactly one tab.** Never open a second QBO tab.

---

Plain-English notes on how the books are kept. Process and context only.
The QuickBooks Online (QBO) UI is the source of truth. Nothing here is a
substitute for what QBO actually shows.

> ## HARD RULE (Greg, 2026-08-19): do not reinvent anything
>
> **Last quarter is already reconciled.** This agent must **not recode, reopen,
> or restructure closed periods.** Use the existing chart of accounts and bank
> flow **as they are** — [`ACCOUNTS.md`](ACCOUNTS.md) and [`BANKS.md`](BANKS.md)
> describe how the file **already works**, not a redesign proposal.
>
> - **Fiscal year starts in January**, so "last quarter" = **Q2 2026 (Apr–Jun)**
>   unless a note here already says otherwise. Q2 2026 is closed.
> - **Current work is Q3 2026** — plus anything still sitting in
>   pending/uncategorized that is clearly *after* the last close. **Even then,
>   ask Greg before moving any amount that might belong in a closed quarter.**
> - **Kirk (Switzer Group) stays head accountant** (annual personal + business
>   filing). **GATP Solutions** were the old quarterly team who did that
>   reconciling; their closed, reconciled quarters are left as they are.

> **Bank and card map:** for which account is which (roles, inflows, outflows,
> deprecated accounts, and open questions for Greg), see [`BANKS.md`](BANKS.md).
>
> **Chart of accounts structure:** for how income, COGS, and expense accounts
> are organized and how work should be coded to them (structure only, no dollar
> amounts; as of 2026-08-19, pending Greg confirmation), see
> [`ACCOUNTS.md`](ACCOUNTS.md).
>
> **Discovered coding rules:** for coding rules observed from the already-labeled
> books (appended as we find them), see [`RULES.md`](RULES.md).

**This repo is public.** No secrets, no bank last-fours, no full account
numbers, no legal or personal detail, no SSNs. Dollar amounts are avoided
unless a number is part of the process itself. Do not paste customer lists or
transaction exports here.

---

## The QBO company

- There is **one live QBO company: INTAGENT** (Intuit's mail refers to it as
  "Intuit QuickBooks Company: INTAGENT").
- Several **trade names live inside that one file** — they are not separate QBO
  companies:
  - **Online VA Team** — client-facing virtual assistant work; accounts
    receivable runs through FreshBooks; payments via Stripe.
  - **WebPixel Pro** — web and design work; has its own Chase checking account
    inside INTAGENT.
  - **Parker Asset Management** — operations and identity; some vendor notices
    come in under this name.

## Income mix

On the GATP Q1 2026 profit-and-loss, income breaks into these categories
(categories only — see QBO for the actual figures):

- **VCS Computer Services Income** — the bulk of revenue.
- **Consulting**.
- **Domain Names**.

## People and payroll

- **Greg is the owner and also an INTAGENT employee.** QBO Auto Payroll runs
  around the 10th of the month.
- Payroll and tax emails also go to the **Switzer** group.

## Accounts receivable (money in)

- **FreshBooks** handles billing, sent from `billings@onlinevateam.com`.
- **Stripe** handles payouts.
- **Client remittances:** MBK and Yardi pay **INTAGENT LLC** via the WebPixel
  address.

## Accounts payable (money out)

- Vendor invoices arrive at `greg.parker@onlinevateam.com`. This is a shared
  mailbox that also receives the webpixelpro and parkerasset aliases. Many
  vendor bills are filed under a **Bills** label.
- **Biggest cost-of-goods vendor: VCS Computer Services.**
- **Other regular operating vendors:** Screenshot Monitor (scrin.io),
  TrafficGuard, Google Workspace, Cloudflare, AWS, Freshdesk, Intuit QBO
  Payroll, and GATP itself (billed quarterly).

## Close process (as run with GATP)

- **Quarterly reconciliation in QBO.**
- Greg reconnects the bank feeds and uploads the **AMEX statement PDFs to
  Google Drive**.
- Greg classifies the leftover items that the bookkeeper cannot identify.
  Examples he has given:
  - "Nation Yearly" → internet.
  - "Hernan" → contractor maintenance.
- **Known issue — Greg booked as a vendor to himself.** This was done in the
  file and Greg pushed back on it.
- **Known issue — AMEX Delta Reserve bank feed could not be enabled.** Greg
  must link that card in QBO.

## Deprecated accounts

- **Raymond James Short Term Savings is deprecated.** It was a company account;
  Greg no longer uses it and it is basically empty.
- **Do not reconnect its broken bank feed (Error 324).** Instead, disconnect
  the feed and make the account inactive in QBO.
- **Keep the historical transactions** — deactivating the account preserves
  them; do not delete anything.
- It was really an investment/brokerage account **miscoded as a Bank**; its
  ETF/fund sub-accounts were inactivated with the parent. See
  [`BANKS.md`](BANKS.md) for the full account-by-account map and the open
  question of whether those subs should be reactivated.

## Firms and hand-offs

- **Old bookkeeping team: GATP Solutions** (`accounting@`), worked quarterly.
  They entered numbers and reconciled. Greg is replacing that quarterly
  bookkeeping with this agent.

## Tax and accountant

- **Kirk (Switzer Group) is the head accountant.** He currently files Greg's
  books every year, for **both personal and business**.
- **This agent does not replace Kirk.** It does not file returns and does not
  give tax advice. Point annual filing questions at Kirk.
- Previously, outside bookkeepers (**GATP Solutions**, quarterly) entered
  numbers and reconciled. Greg wants this agent to do that
  bookkeeping/reconciling going forward, and to organize the QBO file better
  than the old quarterly process.
- **Ask Greg directly when coding is unclear.** Keep working notes here.

## Mailboxes and scope

- Personal and legal mail on Greg's personal Gmail is **not** part of the
  INTAGENT close, unless Greg specifically asks to book an item.

## Documents

- GATP-owned INTAGENT financials workbooks exist, and the AMEX PDFs live in
  Greg's Google Drive. (Financials and AMEX PDFs live in Greg's Google Drive —
  that's enough; file/folder IDs are not needed here.)

---

## Infrastructure note

The hosted QuickBooks Online MCP was removed from the orchestrator box on
2026-08-19 — it was decided to be the wrong tool. Bookkeeping is now done
directly in the QuickBooks Online UI. AdLoop is a separate, unrelated service
and was left untouched. See `NOTES.md` for the decommission detail.
