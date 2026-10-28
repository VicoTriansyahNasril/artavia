# Contract: Transaction CSV (export & import)

- Encoding: UTF-8, export writes a BOM; import accepts with or without BOM.
- Separator `,`; RFC-4180 quoting (fields with `,` `"` or newline are quoted, `"` doubled).
- Line ending: `\r\n` on export; import accepts `\n` or `\r\n`.
- First line is the header, exactly:

```text
date,type,amount,category,account,destination_account,admin_fee,note
```

| Column | Required | Format | Rules |
| ------ | -------- | ------ | ----- |
| date | yes | ISO-8601 `yyyy-MM-ddTHH:mm:ss` (date-only `yyyy-MM-dd` accepted on import) | |
| type | yes | `pengeluaran` \| `pemasukan` \| `transfer` | |
| amount | yes | integer, digits only, > 0 | for transfer = amount received |
| category | for non-transfer | text | created (matching type) if missing |
| account | yes | text | created (type "Lainnya", balance 0) if missing |
| destination_account | for transfer | text | created if missing; must differ from account |
| admin_fee | no | integer ≥ 0 (default 0) | transfer only, charged to sender |
| note | no | text | |

## Import behavior
- Rows failing rules are skipped and reported (line number + reason) in the preview.
- Import is additive; all valid rows are committed in one DB transaction (all-or-nothing on DB error).
- Balances are updated exactly as if each transaction had been entered manually.

## Round-trip guarantee
Export → import into an empty database yields identical transaction count, per-type totals, and account balances relative to zero starting balances (acceptance US4-7).
