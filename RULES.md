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

**This is documentation, not a work order.** Nothing here is a proposal, a
recode, or a fix. Where the books disagree with themselves, the conflict is
**recorded as-is** (see [Observed conflicts](#observed-conflicts)); it is not
resolved here. Per the hard rule in [`BOOKKEEPING.md`](BOOKKEEPING.md), **closed
periods are not recoded or restructured** — current work is dated **after** the
reconcile-through dates below.

**This repo is public.** No balances, no bank last-fours, no statement ending
balances, no full account numbers, no EINs, no dollar amounts (P&L or
otherwise). Accounts are named by role and by their internal QBO
chart-of-accounts code only. Where a title shows a number (e.g. `40106`,
`60051`), that is the internal QBO chart-of-accounts code, not bank data. For
account structure see [`ACCOUNTS.md`](ACCOUNTS.md); for the bank/card money flow
see [`BANKS.md`](BANKS.md).

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

## Reconcile status — observed 2026-08-19

Read off the QBO reconciliation history on a **read-only** pass, 2026-08-19.
This records **where each account is reconciled through as it already stands** —
not a schedule, not a target. **Statement ending balances are intentionally
omitted** (public repo); only reconcile-through dates and session status are
recorded. **Do not recode or re-reconcile closed periods.** Current work is
dated after these dates.

| Account (role) | Reconciled through | Last session done | Prior sessions on file | Status |
|---|---|---|---|---|
| **Checking Chase (main operating)** | **2026-06-30** | 2026-07-17 | 05/29, 04/30, 03/31, 02/27, 01/31/2026 | **Q2 2026 closed** on this account. |
| **`20000` Credit Card – AMEX (Simply Cash)** | **2026-06-30** | 2026-07-17 | 04/06, 03/06, 02/04, 01/07/2026 | Q2 closed **except a May 2026 gap** — **no May 2026 statement row in history.** |
| **`10000` Checking – Comerica** | **2026-04-30** | 2026-07-17 | 03/31, 02/28, 01/31/2026 | **A May 31 2026 reconcile session is in progress** ("Resume reconciling"). |
| **WebPixel Chase** | — | — | — | No reconcile history surfaced. |
| **Amex Delta** | — | — | — | No reconcile history surfaced. (Feed stale since May 2026 — see [`BANKS.md`](BANKS.md).) |
| **Intagent 10 Year Note (Chase Savings)** | — | — | — | No reconcile history surfaced. Dormant apart from interest. |
| **Chase Savings** | — | — | — | No reconcile history surfaced. Unused shell. |
| **PPP Fund subs (under Comerica)** | — | — | — | No reconcile history surfaced. Legacy / dead. |

Observed notes on the above:

- **Chase operating and AMEX Simply Cash are reconciled through 2026-06-30**
  (both done 2026-07-17), so **Q2 2026 (Apr–Jun) is closed** on those two
  accounts.
- **AMEX Simply Cash has no May 2026 statement row** in its reconcile history —
  the sessions jump from 04/06 to the 2026-06-30 close. Recorded as observed;
  **not** something to "fill in" here.
- **Comerica is reconciled through 2026-04-30** and has a **May 31 2026 session
  in progress** ("Resume reconciling"). **Do not touch the in-progress Comerica
  session unless Greg says so.**
- **Hard rule still applies:** do not reinvent, do not recode closed periods.
  Anything after these reconcile-through dates is current work.

---

## Bank rules — observed 2026-08-19

Transcribed faithfully from the QBO **bank-feed rules** list on a read-only pass,
2026-08-19. **50 rules, all Active.** This is a mirror of the rules **as they
already exist** — not a proposal, not a cleanup. Rules that upstream marked as a
QBO **suggestion** are shown as **(Sugg)**. Bank last-fours are omitted: the
account a rule is scoped to is named by role (e.g. "Checking Chase (operating)")
rather than by any bank-issued digits.

Columns: **#** (QBO rule order) · **Rule name** (as titled) · **Applies to**
(account scope) · **Bank-text match** · **Codes to** (QBO account + payee, as
set) · **Flag** (any QBO warning observed).

| # | Rule name | Applies to | Bank-text match | Codes to (account / payee) | Flag |
|---|---|---|---|---|---|
| 1 | Stripe probably Intagent | All | Bank text **contains** `STRIPE INC` | `40104` Intagent Services; payee **Intagent Websites** | |
| 2 | Stripe as VCS Computer Services Income | All | Bank text **contains** `STRIPE` | `40106` VCS Computer Services Income; payee **VCS Computer Services Income** | |
| 3 | (Sugg) Ads Cc | All | Desc **contains** `Google` | `60000` Advertising; payee **Google Adws** | **Can't apply — posts to a locked account.** |
| 4 | (Sugg) Amazon web services | All | `Amazon web services` | `50108` R&M Computer Equipment; payee **Amazon.com** | |
| 5 | (Sugg) Basecamp | All | `Basecamp` | `60104` Other Online Services | |
| 6 | VCS Computer Services Income as Stripe | Comerica | specific `STRIPE TRANSFER` id | `40106` VCS Income (auto-post) | |
| 7 | Chevron | AMEX | `Chevron` | `60051` Gas | |
| 8 | San Francisco Ca. | AMEX | same | `60205` Email Marketing; payee **Adroll** | |
| 9 | Upwork | AMEX | `Upwork` | `50202` Contractors | |
| 10 | Union 76 | AMEX | `Union 76` | `60051` Gas | |
| 11 | COINBASE INC… | Comerica | `Coinbase` | `50202` Contractors | |
| 12 | Shell | AMEX | `Shell` | `60051` Gas | |
| 13 | Domain Names Hosting | AMEX | same | `50106` Domain | |
| 14 | Your Cash Back | AMEX | same | `40550` Misc Income | |
| 15 | QuickBooks | AMEX | `QuickBooks` | `60102` Software | **Locked-account warning.** |
| 16 | Cox Orange Ca | AMEX | same | `60000` Advertising; payee **Cox Orange** | |
| 17 | Country Dairy New | AMEX | same | `60150` Meals | |
| 18 | Marathon | AMEX | `Marathon` | `60051` Gas | **Locked-account warning.** |
| 19 | Trafficguard Bentley Au | AMEX | same | `60000` Advertising; payee **TrafficGuard** | |
| 20 | Delta | AMEX | `Delta` | `60450` Travel | |
| 21 | GitHub | AMEX | `GitHub` | `60104` Other Online Services | |
| 22 | J Onebox Services | AMEX | same | `60400` Communication | |
| 23 | Wal-Mart | AMEX | `Wal-Mart` | `60200` Office Supplies | |
| 24 | Fast Laguna Nigu | AMEX | same | `60050` Auto | |
| 25 | Oak Land | AMEX | `Oak Land` | `60205` Email Marketing; payee **Mailup** | |
| 26 | eBay | AMEX | `eBay` | `60200` Office Supplies | |
| 27 | Bootstrapped Venturestevoort Li | AMEX | same | `50106` Domain | |
| 28 | Ads Cc (2) | AMEX | `Ads Cc` | Advertising:**Social Media**; payee **Google Adws** | |
| 29 | Foreign Transaction Fee | AMEX | same | `60600` Bank Service Charges | |
| 30 | Domainnames Az Gregory | AMEX | same | `50106` Domain | |
| 31 | Johnwayneairport… | AMEX | same | `60450` Travel | |
| 32 | Wild West Domains | AMEX | same | `60205` Email Marketing | |
| 33 | Www Saleshandy.com | AMEX | same | `60102` Software | |
| 34 | Bridge Philanthr Ach | Comerica | same | `40106` VCS Income | |
| 35 | Online Us Dollar | Chase operating | same | `60600` Bank fees | |
| 36 | Jpmorgan Chase Ext | Comerica | same | `31400` Shareholder Distributions | |
| 37 | Salesql Starter… | AMEX | same | `60102` Software | |
| 38 | Saleshandy.com Gregory Z | AMEX | same | `60205` Email Marketing | |
| 39 | Dnh Domain Name | AMEX | same | `50106` Domain | |
| 40 | Speedway | AMEX | `Speedway` | `60051` Gas | |
| 41 | Amazon | AMEX | `Amazon` | `60102` Software | |
| 42 | American Express | AMEX | same | `60452` Travel transportation | |
| 43 | Domain Hosting Az | AMEX | same | `50106` Domain | |
| 44 | Apple | AMEX | `Apple` | `60100` Computer and Internet | |
| 45 | Home Depot | AMEX | `Home Depot` | `60200` Office Supplies | |
| 46 | Crr Incorporated | AMEX | `Crr Incorporated` | Garbage & Recycling | |
| 47 | DNH DOMAINS | AMEX | `Dnh Domains` | `50106` Domain | |
| 48 | DOMAIN NAMES | AMEX | `DOMAIN NAMES` | `50106` Domain | |
| 49 | GAIA Subscrip | AMEX | `GAIA Subscrip` | Dues and Subscription | |
| 50 | COX ORANGE CO | AMEX | `COX ORANGE` | `51000` Internet Expense | |

---

## Observed conflicts

Recorded **as-is**, not resolved. These are places where the rules or the posted
history already disagree with themselves. Per working rule #1 (do not reinvent),
**nothing here is being "fixed"** — the disagreement is documented so it is not
mistaken for an error later, and so it can be raised with Greg / Kirk rather than
silently recoded.

- **Two Stripe rules, different income lines.** Rule 1 (`STRIPE INC` →
  `40104` Intagent Services, payee Intagent Websites) vs. rule 2 (`STRIPE` →
  `40106` VCS Computer Services Income). Both **All**; the broader `STRIPE`
  match overlaps the narrower `STRIPE INC` match.
- **Two Google-ads rules, different destinations.** Rule 3 ((Sugg) Ads Cc,
  `Google` → `60000` Advertising) vs. rule 28 (Ads Cc (2), `Ads Cc` →
  Advertising:**Social Media**). One posts to plain Advertising, the other to
  the Social Media sub.
- **Cox coded two ways.** Rule 16 (Cox Orange Ca → `60000` Advertising) vs.
  rule 50 (COX ORANGE CO → `51000` Internet Expense). Same vendor, two
  categories.
- **Amazon posts split by direction.** In posted history, Amazon **charges**
  land in `60102` Software while **credits** land in `65200` Technology.
  _For **new** posts, Greg's guidance below overrides this: keep all Amazon in
  one bucket — see [Greg's expense coding](#gregs-expense-coding--confirmed-2026-08-19)._
- **VULTR posted under payee Vudu.com.** Observed in posted history — the VULTR
  charge is booked against a payee named **Vudu.com**.
  _For **new** posts, Greg's guidance below overrides this: VULTR is hosting
  (`60102`) and the payee should never be left as Vudu.com — see
  [Greg's expense coding](#gregs-expense-coding--confirmed-2026-08-19)._

---

## Greg's expense coding — confirmed 2026-08-19

Greg's own coding preferences for expenses, **observed and confirmed with Greg**
on 2026-08-19 (not inferred from the feed rules — this is how he says he wants
loose coding to go). Recorded here as guidance for **new posts going forward**.
It does **not** recode closed periods: per the hard rule and the reconcile-through
dates above, **Q1–Q2 2026 stay as posted; these apply Q3 2026 onward (pending).**

Where this guidance conflicts with the 50 QBO bank rules or the posted history,
**Greg's guidance wins for new posts** — the existing rules and history are still
documented above **as-is** and are not being rewritten.

- **Amazon — all of it — is a business expense.** Anything Amazon (Amazon
  Marketplace, **AWS**, even **AMZN Pharmacy**) goes to the general bucket:
  **Software & Web-hosting / software-supplies (`60102`)**. **Do not split
  Amazon across many accounts.** _(This overrides the observed Amazon
  charge/credit split into `60102`/`65200`, and the feed rule #4 that sends
  `Amazon web services` to `50108`, for new posts.)_
- **VULTR is hosting / computer → `60102`.** **Never leave the payee as
  Vudu.com** — set the payee to VULTR. _(Overrides the observed VULTR-under-Vudu.com
  posting for new posts.)_
- **Restaurants (e.g. Rances) → Meals and Entertainment (`60150`).**
- **CRR / garbage → office Garbage & Recycling.** Do **not** treat as personal.
- **Ad Creative (or similar) credits → internet advertising refund →
  `60000` Advertising and Promotion.**
- **Greg codes loose — do not over-split.** Only stop and **ask** when
  something looks **clearly personal**.
- **Closed quarters are still not recoded.** These rules apply **going forward**
  (Q3 2026 and later, pending).

---

## Posted patterns — observed 2026-08-19

Short list of how transactions were **already posted** in register history
(distinct from the feed rules above). Observed, not invented; recorded to keep
coding consistent, not to change anything.

**Comerica (checking `10000`):**

- Intuit **payroll** → Direct-Deposit (DD) payable.
- Intuit **payroll tax** → tax holding.
- **GoDaddy** → `40100` Domain Names.
- **National Assoc** reimbursement → `40106` VCS.
- **FTB** (Franchise Tax Board) → Business Taxes.
- **Door repair** → `67200`.

**AMEX (`20000` Credit Card, Simply Cash):**

- **Intuit QuickBooks** → `60102` Software.
- **Apple** → `60100` Computer and Internet.
- **Facebook** → Advertising:Social Media.
- **Grok / Google Cloud** → `60102` Software.
- **GAIA** → Dues and Subscriptions.
- **Cox** → `51000` Internet Expense.
- **Cash back** → `40550` Misc Income.
- **AMEX autopay** → transfer to Chase operating (**not** an expense — card
  liability payment).
- **ASAE / Hargrove** → Tradeshow.

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
process notes — including **do not reinvent** and the **exactly one QBO tab**
rule — [`BANKS.md`](BANKS.md) for the bank/card map, [`ACCOUNTS.md`](ACCOUNTS.md)
for the chart-of-accounts structure, and [`STATEMENTS.md`](STATEMENTS.md) for
where reconciliation statements are filed. **Kirk (Switzer Group) remains the
head accountant** for annual personal and business filing; **GATP Solutions**
were the old quarterly bookkeepers._
