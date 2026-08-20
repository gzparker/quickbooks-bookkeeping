# Chart of accounts — structure

Plain-English map of the **structure** of the chart of accounts (COA) in the one
QBO company (**INTAGENT** — see [`BOOKKEEPING.md`](BOOKKEEPING.md)): how the
income, cost-of-goods, and expense accounts are organized and how work should be
coded to them. Structure and coding logic only — **no balances, no dollar
amounts, no P&L figures.** The QuickBooks Online (QBO) UI is the source of truth.

**This repo is public.** No secrets, no bank last-fours, no full account
numbers, no live balances, no dollar amounts (including P&L totals or YTD
activity), no EINs. Accounts are named by their role and QBO chart-of-accounts
code only. Where a title shows a number (e.g. `40000`, `50000`), that is the
internal QBO chart-of-accounts code, not bank or tax data.

> **Status: as of 2026-08-19, pending Greg confirmation.** Unlike the bank/card
> map in [`BANKS.md`](BANKS.md) (confirmed by Greg 2026-08-19), the account
> structure and coding rule below were read off the QBO COA list and have **not**
> yet been confirmed by Greg. Treat everything here as a working draft until he
> or Kirk (Switzer Group, head accountant) signs off. This is the picture **so
> far** — accounts could be renamed, merged, or retired.

---

## Income — `40000` Sales and subs

Revenue is organized by service line under a `40000 Sales` parent:

- `40000` Sales
- `40100` Domain Names
- `40101` Consulting Income
- `40102` IDX Services
- `40104` Intagent Services
- `40106` VCS Computer Services Income — **the bulk of revenue.**

Alongside those are the usual QBO default / stub income accounts that look
**unused**: Refund, Billable Expense Income, Markup, Sales of Product Income, and
Uncategorized Income. Do not code new work to the stubs; use the numbered
service lines.

## Other income

Non-operating income sits separately from the `40000` service lines:

- `40500` Interest Income
- `40550` Miscellaneous Income

Plus a set of legacy / investment-flavored accounts that look tied to the old
brokerage activity (see the Raymond James note in [`BANKS.md`](BANKS.md)):
Dividend & Investment Income, Exempt Interest Income, Gain/Loss on Sale, Closing
Costs, PPP Forgiveness Income, and Unrealized Gain/Loss. **PPP-related accounts
look legacy.**

## COGS — `50000`s (meant to mirror the income lines)

Cost-of-goods accounts are numbered to shadow the income service lines:

- `50000` SEO
- `50100` Website Related Expenses
  - `50102` IDX
  - `50104` Payment Processer *(spelling as it appears in the COA)*
  - `50106` Domain
  - `50108` R&M Computer Equipment
- `50200` Outside Labor – COS
  - `50202` Contractors
  - `50204` Outside Support
  - `50206` VCS Computer Services Cost
- `52000` Outside Reseller Services

There is also a generic, **unnumbered** `Cost of Goods Sold` account that
**overlaps** with the numbered COGS lines above — a candidate for cleanup /
consolidation once Greg confirms.

## Operating expenses — `60000`s (organized by function)

Opex is grouped by function under the `60000` range. Summarized groups (leaf
accounts intentionally not all listed to keep this readable):

- Advertising — `60000`
- Auto — `60050`
- Computer / Internet — `60100` — **note overlap** with `65200` Technology and
  `51000` Internet (three places that can absorb the same kind of cost).
- Meals — `60150`
- Travel — `60450`
- Officer Wages — `60250`
- Payroll — `60300`
- Consulting — `60700`
- Office / professional / legal / bank charges — `60600`
- Insurance — `63300`
- CA LLC tax — `69000`
- Plus the usual overhead: rent, repairs & maintenance, and similar.

## Catch-alls / mess (clean-up piles)

Accounts that collect unsorted or unclear activity — these are the cleanup
targets, **not** places to code new work on purpose:

- **Uncategorized Income** and **Uncategorized Expense** — large YTD activity
  (the cleanup pile; dollar amounts intentionally omitted).
- **Uncategorized Asset.**
- `80000` Ask My Accountant.
- Reconciliation Discrepancies.
- `67300` Miscellaneous.
- `6210` General Expense — an **odd 4-digit number** that breaks the 5-digit
  numbering pattern; flag for Greg.

---

## Coding rule (inference)

How work *should* be coded, inferred from the structure above — **pending Greg
confirmation:**

1. **Revenue** → tag by service line under `40xxx` (Domain Names, Consulting,
   IDX, Intagent Services, VCS Computer Services Income).
2. **Pass-through / contractor / VCS labor** → the matching `50xxx` COGS line
   (e.g. VCS labor → `50206`; contractors → `50202`).
3. **Internal overhead** → the appropriate `60xxx` function.
4. **Unclear** → `80000` Ask My Accountant / Uncategorized, and leave it there
   until Greg or Kirk says how to code it. Do not guess into a real account.

---

## Notes and open questions

- **No class or location columns** were seen on the COA list — no
  class/location tracking to rely on for splitting the trade names.
- **Mixed personal-looking accounts exist** in the file (medical, auto / Tesla,
  owner draw). These are *not* listed here as confirmed personal — just noting
  they exist. **Do not recode them without Greg.**
- **PPP accounts / income look legacy** (see Other income and the PPP subs in
  [`BANKS.md`](BANKS.md)).
- **Overlaps to resolve** once confirmed: shipping vs. postage; computer
  (`60100`) vs. technology (`65200`); and **two insurance spots**.

---

_See [`BOOKKEEPING.md`](BOOKKEEPING.md) for the surrounding process notes and
[`BANKS.md`](BANKS.md) for the bank/card map. **Kirk (Switzer Group) remains the
head accountant** for annual personal and business filing; **GATP Solutions**
were the old quarterly bookkeepers._
