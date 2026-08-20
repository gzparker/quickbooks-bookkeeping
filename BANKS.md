# Bank and card map

Plain-English map of the bank and credit-card accounts in the one QBO company
(**INTAGENT** — see [`BOOKKEEPING.md`](BOOKKEEPING.md)) and what each one is for.
Roles, not numbers. The QuickBooks Online (QBO) UI is the source of truth.

**This repo is public.** No secrets, no bank last-fours, no full account
numbers, no live balances, no dollar amounts from registers, no EINs. Accounts
are named by their role and platform, not by any bank-issued digits. Where a
title below shows a number (e.g. `10000`, `20000`), that is the internal QBO
chart-of-accounts code, not bank data.

Items marked _(inferred)_ were read off transaction patterns. Greg confirmed
the bank/card map below is the flow — **confirmed by Greg 2026-08-19** — so
these lines are no longer pending. This is the picture **so far**; more
accounts could appear later.

---

## How money flows (short version)

Two operating inflows feed the business, and each has a home account:

- **Stripe payouts and international client wires** (e.g. association / VCS
  clients) land in **Chase operating**.
- **Domain-name deposits** (GoDaddy) land in **Comerica**.
- **Consulting and MBK Real Estate** money lands in **WebPixel Pro Chase**.

**Payroll and payroll taxes** are paid out of **Comerica**. **Credit cards** are
paid from **operating (Chase)** and **WebPixel Pro Chase**. **VCS
cost-of-goods labor wires** (Philippines reseller / VCS) go out of **Chase
operating**.

This flow — Chase operating, Comerica payroll, and WebPixel Pro Chase — is
**confirmed by Greg 2026-08-19** (so far).

---

## Bank accounts

### Chase Checking — main operating
- **Role:** primary operating account.
- **In:** Stripe payouts; international client wires (e.g. association / VCS
  clients).
- **Out:** Philippines reseller / VCS labor wires (cost of goods); AMEX
  autopay; some shareholder distributions; wire fees.
- **Note:** the QBO display name carries a bank-side account fragment; it is
  intentionally omitted here (public repo). Identify it in QBO by role, "main
  operating."
- **Confirmed by Greg 2026-08-19.**

### Checking Comerica (`10000`)
- **Role:** payroll and payroll-tax account.
- **In:** GoDaddy / domain-name deposits; occasional other.
- **Out:** payroll and payroll-tax withdrawals.
- **Confirmed by Greg 2026-08-19.**

### WebPixel Pro Chase Checking
- **Role:** WebPixel Pro / consulting account.
- **In:** MBK Real Estate ACH; consulting deposits.
- **Out:** large American Express payments.
- **Confirmed by Greg 2026-08-19.**

### Intagent 10 Year Note — Chase Savings
- **Role:** savings holding a 10-year note.
- **Activity:** only tiny interest posts; effectively **dormant**. _(inferred;
  confirmed by Greg 2026-08-19)_

### Chase Savings
- **Role:** unused empty shell. No activity. _(inferred; confirmed by Greg
  2026-08-19)_

### 10 Year Note Repayment
- **Role:** empty placeholder. No activity. _(inferred; confirmed by Greg
  2026-08-19)_

### PPP Fund 60% Payroll and PPP Fund 40% Others (subs of Comerica)
- **Role:** legacy PPP tracking sub-accounts under Comerica.
- **Activity:** empty / dead. Kept for history only. _(inferred; confirmed by
  Greg 2026-08-19)_

---

## Credit cards

### `20000` Credit Card — AMEX
- **Role:** primary business card (software, ads, travel).
- **Paid from:** Chase operating.
- **Confirmed by Greg 2026-08-19.**

### Amex Delta
- **Role:** secondary card; mixed business / personal. _(inferred; confirmed by
  Greg 2026-08-19)_
- **Feed status:** bank feed is **stale — last updated May 2026.** The role is
  confirmed by Greg 2026-08-19, but the feed is still stale, so do **not** treat
  this card's register as current until the feed is refreshed.

---

## Deprecated

### Raymond James Short Term Savings — DEPRECATED
- **Status:** disconnect is done; account is inactive; **history kept.**
  **Confirmed by Greg 2026-08-19.**
- **What it really was:** an investment / brokerage account that had been
  **miscoded as a Bank** account.
- **Sub-accounts:** the ETF / fund sub-accounts under it were inactivated
  together with the parent. QBO auto-posted opening-balance-equity adjustments
  when they were inactivated (amounts intentionally not described here).

---

## Confirmed by Greg (2026-08-19)

Greg confirmed on 2026-08-19 that the bank/card map above is the flow. The
items previously flagged for him resolve as follows — **confirmed by Greg
2026-08-19** — with the caveat that this is the picture **so far** and more
accounts could appear later:

- **Raymond James subs:** the inactivated ETF / fund sub-accounts stay
  inactive with history kept (not reactivated).
- **Amex Delta:** secondary, mixed business / personal card. The bank feed is
  still stale (last updated May 2026), so its register is not current even
  though the role is confirmed.
- **Chase Savings shells** (`Chase Savings`, `10 Year Note Repayment`) and the
  **PPP Fund subs:** dead; they stay dormant / hidden.
- **Intagent 10 Year Note savings:** dormant apart from interest.

---

_See [`BOOKKEEPING.md`](BOOKKEEPING.md) for the surrounding process notes
(income mix, payroll, close process, firms and hand-offs). Kirk (Switzer Group)
remains the head accountant for annual personal and business filing; GATP
Solutions were the old quarterly bookkeepers._
