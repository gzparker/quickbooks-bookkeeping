# Discovered coding rules

These are coding rules **observed from the existing, already-labeled books** —
how prior bookkeepers actually coded and reconciled transactions in the one QBO
company (**INTAGENT** — see [`BOOKKEEPING.md`](BOOKKEEPING.md)). They are
**observed, not invented.** We follow the file as it already is (working rule #1:
do not reinvent) and record what we find so we code the same way next time
(working rule #2: document as you discover).

New rules get **appended here as we discover them** from already-labeled
transactions. Each entry should say what you saw and how it was already coded,
and be marked as observed from the existing books — not a new scheme.

**This repo is public.** No balances, no bank last-fours, no full account
numbers, no EINs, no dollar amounts (P&L or otherwise). Accounts are named by
role and by their internal QBO chart-of-accounts code only. For account
structure see [`ACCOUNTS.md`](ACCOUNTS.md); for the bank/card money flow see
[`BANKS.md`](BANKS.md).

---

## Rules known so far

_All observed from existing books, not invented._

| What you see | How it was already coded | Notes |
|---|---|---|
| **Nation Yearly** | Internet | Recurring; classified as internet by Greg / prior team. |
| **Hernan** | Contractor maintenance | Contractor maintenance (see close-process examples in [`BOOKKEEPING.md`](BOOKKEEPING.md)). |
| **Stripe payouts** | Chase operating → VCS or Sales, as already used | Payouts land in Chase operating; income coded to the service line already in use (VCS / sales). Follow the existing coding, don't re-split. |
| **Philippines "RESELLER SERVICES" wires** | `50206` VCS Computer Services Cost | Outbound cost-of-goods labor wires; coded to the `50206` COGS line. |
| **MBK / Yardi ACH** | WebPixel Pro Chase → Consulting | Client remittances landing in WebPixel Pro Chase, coded as Consulting. |
| **GoDaddy deposits** | Comerica → Domain Names | Domain-name deposits land in Comerica, coded to Domain Names. |
| **Owner paycheck + Intuit payroll tax** | Comerica | Payroll and payroll-tax activity runs out of Comerica. |
| **AMEX autopay from operating / WebPixel Pro Chase** | Transfer / card payment — **not an expense** | It's a payment on the card liability, not a P&L expense. Do not book it as an expense. |
| **Raymond James** | Deprecated — **do not reconnect** | Account is inactive with history kept; the broken feed (Error 324) stays disconnected. See [`BANKS.md`](BANKS.md). |

---

## Statement filing on Google Drive — observed 2026-08-19

Observed from Greg's Drive on 2026-08-19 (not invented). Reconciliation source
statements are filed under a Google Drive parent folder named **`Intagent`**
(owned by `intagent.talk@gmail.com`), **one folder per year**, with
per-institution subfolders: **AMEX** (two cards — Simply Cash and Delta),
**Chase**, and **Comerica**.

- **When a new year starts, create a new year folder** under `Intagent` and file
  every statement needed for that year's reconciliation inside it.
- The two AMEX cards map to QBO as: **Simply Cash → `20000 Credit Card – AMEX`**
  (primary business card); **Delta → Amex Delta**.
- **Raymond James is deprecated** — do **not** create a Raymond James folder for
  2026+; keep old year folders as history (see [`BANKS.md`](BANKS.md)).

See [`STATEMENTS.md`](STATEMENTS.md) for the full folder map, the AMEX card → QBO
mapping, and current 2026 status.

---

_See [`BOOKKEEPING.md`](BOOKKEEPING.md) for the working rules and surrounding
process notes, [`BANKS.md`](BANKS.md) for the bank/card map,
[`ACCOUNTS.md`](ACCOUNTS.md) for the chart-of-accounts structure, and
[`STATEMENTS.md`](STATEMENTS.md) for where reconciliation statements are filed._
