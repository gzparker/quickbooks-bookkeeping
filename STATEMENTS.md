# Reconciliation statements — Google Drive filing

Where the source statements for QBO reconciliation live and how the folders are
organized. **Observed 2026-08-19** from Greg's Drive — this documents the filing
**as it already is** (working rule #1: do not reinvent), not a proposed layout.
The QuickBooks Online (QBO) UI is the source of truth for the books; this file
only records where the backup statement PDFs are filed.

**This repo is public.** No statement contents, no balances, no bank last-fours,
no full account numbers, no EINs, no dollar amounts. Folders are named by their
role and platform only. Where a title shows a number (e.g. `20000`), that is the
internal QBO chart-of-accounts code, not bank data.

---

## Where they live

- **Parent folder: `Intagent`** in Google Drive, owned by `intagent.talk@gmail.com`.
- Greg's link (parent folder):
  <https://drive.google.com/drive/u/0/folders/0B6tb7fMug3VGeW4zSU9oeTVOak0?resourcekey=0-AaSevxM5kUJhb_bM0aqz7w>
- The parent URL above is enough. Individual PDF names and per-subfolder Drive
  IDs are intentionally **not** listed here.

## Folder structure

- Under **`Intagent`**, one folder **per year**: 2017, 2018, 2019, 2020, 2021,
  2022, 2023, 2024, 2025, 2026 — plus an `_old` folder for archived material.
- **Rule (observed):** when a new year starts, create a new year folder under
  `Intagent` and file every statement needed for that year's reconciliation
  inside it.
- Inside each year folder, statements are grouped by institution:
  - **AMEX** — two cards (see below)
  - **Chase**
  - **Comerica**

## The two AMEX cards

Each year's AMEX folder holds two cards. The naming has drifted between years,
but the two cards are the same, and each maps to a QBO account:

| Card | 2026 folder | 2025 folder | Maps to (QBO) |
|---|---|---|---|
| Simply Cash | `AMEX/Simply Cash` | `amex/amex simply cash` | `20000 Credit Card – AMEX` — primary business card |
| Delta | `AMEX/Delta` | `amex/delta amex` | Amex Delta |

See [`BANKS.md`](BANKS.md) for the card roles and feed status.

## Deprecated / not carried forward

- **Raymond James:** the 2025 year folder also has a `raymond james` folder.
  Raymond James is **deprecated** (see [`BANKS.md`](BANKS.md) and
  [`RULES.md`](RULES.md)) — **do not create a Raymond James folder for 2026 or
  later.** Keep the old year folders as history; do not delete them.

## 2026 status (as of 2026-08-19)

- The **2026** year folder currently contains **only AMEX** (Delta + Simply
  Cash).
- **Chase** and **Comerica** folders are **not created yet for 2026.** Do not
  assume they exist — they should be added when those statements are filed.

---

_See [`BOOKKEEPING.md`](BOOKKEEPING.md) for the surrounding process notes (income
mix, payroll, close process), [`BANKS.md`](BANKS.md) for the bank/card map,
[`ACCOUNTS.md`](ACCOUNTS.md) for the chart-of-accounts structure, and
[`RULES.md`](RULES.md) for discovered coding rules. Kirk (Switzer Group) remains
the head accountant for annual personal and business filing; GATP Solutions were
the old quarterly bookkeepers._
