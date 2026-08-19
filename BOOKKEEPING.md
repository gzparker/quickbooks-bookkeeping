# Bookkeeping working notes

Plain-English notes on how the books are kept. Process and context only.
The QuickBooks Online (QBO) UI is the source of truth. Nothing here is a
substitute for what QBO actually shows.

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
