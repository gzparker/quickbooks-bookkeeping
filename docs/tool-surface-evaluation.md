# Tool surface evaluation

Measured against the pinned build (`c351dc0`) by starting the server over stdio
with dummy credentials and reading `tools/list`. No QuickBooks company was
contacted, so this covers the *shape* of the surface, not data quality.

Re-run after any upstream bump; the numbers below are the baseline.

## Headline numbers

| | tools | create | update | delete | get/read | search |
| --- | --- | --- | --- | --- | --- | --- |
| Unflagged | 142 | 25 | 26 | 20 | 42 | 29 |
| All three `DISABLE_*` flags | **71** | 0 | 0 | 0 | 42 | 29 |

Upstream advertises "144 tools"; 142 actually register. The flags suppress
exactly the 71 mutating ones, and suppression happens at registration, so the
mutating tools are never advertised rather than merely refused.

## Context cost

The `tools/list` payload is **~42,900 characters, roughly 10,700 tokens**, sent
on every turn. Real but affordable — the surface is not the reason to build a
gateway. Descriptions are uniformly present, median 60 characters.

## The actual problem: search tools are untyped

Report tools are well built. `get_profit_and_loss` exposes typed `start_date`,
`end_date`, an `accounting_method` enum of `Cash`/`Accrual`, and a
`summarize_column_by` enum — everything a model needs to call it correctly.

The 29 `search_*` tools are not:

```json
{
  "type": "object",
  "properties": {
    "params": {
      "type": "object",
      "properties": { "criteria": {} },
      "additionalProperties": false
    }
  },
  "required": ["params"]
}
```

`criteria` has an **empty schema** — no type, no properties, no description, no
example. The tool description says it "maps to node-quickbooks
`findInvoices`", which is an implementation detail an agent cannot act on.

So on 29 of 71 tools the model must guess an undocumented object shape. It will
guess wrong, and the failure is a confusing API error rather than a schema
validation message.

### Consequence for how agents should work

This is the empirical basis for the "reports first, search only for row-level
detail" rule in `AGENTS.md`. It is not a style preference — the report tools are
genuinely well specified and the search tools genuinely are not.

## Minor findings

- **Naming is inconsistent but barely.** 69 tools use `snake_case`, 2 use
  hyphens (`get-bill` among them). Any name matching must handle both, which is
  why the read-only assertion in `RUNBOOK.md` matches `(create|update|delete)[_-]`.
- **Everything is nested under a `params` wrapper**, adding a level for no gain.
- No tool exposes a raw QuickBooks query endpoint, so there is no escape hatch
  when the typed surface cannot express a question.

## What this means for the gateway

It sharpens the case, and changes its priority order.

The original argument was that too many tools degrade selection. That is the
weaker reason: 71 tools at ~10,700 tokens is tolerable. The stronger reason is
that **29 tools are effectively uncallable without trial and error**.

If the gateway gets built, the highest-value pieces are therefore:

1. `qb_search` with a real, typed schema per entity — replacing the untyped
   `criteria` blob. This is most of the benefit.
2. `qb_query` exposing the QuickBooks query language directly, as the escape
   hatch upstream lacks.
3. Collapsing the 42 fetch tools via enum dispatch — genuine but secondary.

Write-side draft/confirm remains a separate prerequisite for ever enabling
writes, unrelated to these usability problems.
