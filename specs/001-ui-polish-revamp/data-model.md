# Data Model: UI Polish & Feature Completion Revamp

DB version 10 → 11. Only one new table; existing tables unchanged.

## New: `recurring_rules`

| Column | Type | Constraint | Notes |
| ------ | ---- | ---------- | ----- |
| id | INTEGER | PK AUTOINCREMENT | |
| type | TEXT | NOT NULL, in (`pengeluaran`,`pemasukan`) | transfers not supported |
| amount | INTEGER | NOT NULL, > 0 | |
| category_id | INTEGER | NOT NULL, FK categories(id) ON DELETE CASCADE | |
| account_id | INTEGER | NOT NULL, FK accounts(id) ON DELETE CASCADE | |
| note | TEXT | NOT NULL DEFAULT '' | |
| frequency | TEXT | NOT NULL, in (`daily`,`weekly`,`monthly`) | |
| start_date | TEXT | NOT NULL | ISO-8601 date (yyyy-MM-dd) |
| last_run_date | TEXT | NULL | ISO date of last generated occurrence |
| is_active | INTEGER | NOT NULL DEFAULT 1 | 0/1 |

Migration (v11): `CREATE TABLE IF NOT EXISTS recurring_rules (...)` in `_upgradeDB` when `oldVersion < 11`, and in `_createDB`.

### Validation
- amount > 0; category type == rule type; account exists.
- Editing `start_date` or `frequency` resets `last_run_date` to NULL only if new start_date > today; otherwise keeps it (no back-fill duplicates).

### State lifecycle
`active` ⇄ `paused` (is_active toggle) → `deleted`. Generation only for `active`.

### Occurrence rules (`dueDates`)
- first = last_run_date ? next(last_run_date) : start_date
- next: daily +1d; weekly +7d; monthly → same day as start_date in next month, clamped to last day.
- yield while occurrence <= today (date only); max 400.

## Existing entities (unchanged schema, behavior notes)

- **transactions**: `admin_fee`, `admin_fee_type` now propagated through models/args (FR-018).
- **accounts**: `is_excluded` respected by `computeNetWorth` everywhere (FR-013).
- **categories**: `color_val` for new categories chosen from `categoryPalette`; default seed colors updated (fresh installs only).
- **budgets**: keyed (year, month) = period label month; usage computed over `PeriodService.rangeFor`.
- **settings**: new keys → [contracts/settings-keys.md](contracts/settings-keys.md).

## Derived (not persisted)

- **NetWorth**: {asset, liability, net} from non-excluded accounts.
- **TrendBucket**: {x, label, amount} per mode.
- **BudgetSummary**: {totalBudget, totalUsed, overCategories[]} for active period.
