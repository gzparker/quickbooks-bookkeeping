# Tool surface evaluation

Measured against the pinned build (`c351dc0`) by starting the server over stdio
and reading `tools/list`. No QuickBooks company was contacted, so this covers
the *shape* of the tool surface, not data quality.

The tool counts and the read-only verification live in `RUNBOOK.md`. This file
is about how usable the remaining 71 tools actually are, because they are not
equally good and the difference should drive how agents work.

Re-run after any upstream pin bump.

## Reports are well specified

`get_profit_and_loss` is representative:

```json
{
  "start_date":          { "type": "string", "description": "Start date (YYYY-MM-DD)" },
  "end_date":            { "type": "string", "description": "End date (YYYY-MM-DD)" },
  "accounting_method":   { "type": "string", "enum": ["Cash", "Accrual"] },
  "summarize_column_by": { "type": "string", "enum": ["Total","Month","Week","Days","Classes"] }
}
```

Typed, enumerated, described. A model can call this correctly first try.

## Search tools are not

All 29 `search_*` tools take a single `criteria` parameter whose schema is
**empty**:

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

No type, no properties, no description, no example. The tool description says
it "maps to node-quickbooks `findInvoices`" — an implementation detail an agent
cannot act on without reading that library's source.

So on 29 of 71 tools the model must guess an undocumented object shape, and a
wrong guess surfaces as an opaque API error rather than a schema validation
message. The failure is also easy to misread as "no matching records," which is
worse than an error, because it looks like a finding about the books.

### Consequence

This is the empirical basis for "prefer reports over reconstruction" in
`AGENTS.md` and `.cursor/rules/qbo.mdc`. It is not a stylistic preference: one
half of the surface is properly specified and the other half is not.

It compounds with the pagination caveat already documented for search — an
unbounded search returns a truncated window that looks complete. Guessing at
`criteria` *and* silently truncating is how an agent produces a confident wrong
total.

## Context cost

The `tools/list` payload is ~42,900 characters, roughly **10,700 tokens**, sent
every turn. Real but affordable. Descriptions are uniformly present, median 60
characters — short, but adequate for the typed tools.

## Minor findings

- **Naming is inconsistent.** 69 tools use `snake_case`; 2 use hyphens
  (`get-bill` among them). Any name-based matching must handle both — which is
  also why the disable flags' prefix matching is worth re-checking on pin bumps.
- **Everything nests under a `params` wrapper**, adding a level for no gain.
- **No raw query tool.** Upstream exposes no QuickBooks query-language endpoint,
  so there is no escape hatch when the typed surface cannot express a question.

## What this means for the gateway

It sharpens the case and reorders it.

The original argument was that too many tools degrade selection. That is the
weaker reason — 71 tools at ~10,700 tokens is tolerable. The stronger reason is
that **29 tools are effectively uncallable without trial and error**.

So if the gateway gets built, priority order is:

1. **`qb_search` with a real typed schema per entity**, replacing the untyped
   `criteria` blob, with explicit pagination. Most of the benefit lives here.
2. **`qb_query`** exposing the QuickBooks query language as the escape hatch
   upstream lacks.
3. Collapsing the 42 fetch tools via enum dispatch — genuine but secondary.

Write-side draft/confirm remains a separate prerequisite for ever enabling
writes, and is unrelated to these usability problems.
