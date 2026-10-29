# UI Component Contracts (`lib/widgets/kobalt/`)

Every screen builds from these; no screen styles a button, chip, field, row, sheet or dialog
itself. Visual values come from [kobalt-design-digest](../inputs/kobalt-design-digest.md).

| Component | Props (minimum) | Variants / states |
|---|---|---|
| `AppScaffold` | title?, leading (back/close/none), actions, body, bottom?, showOrb=true | dark/light; orb hidden when reduceTransparency |
| `AmbientOrb` | alignment | 320 px radial, accent 30 % / 18 % |
| `GlassCard` | level (ultra/tipis/reguler/tebal), radius, padding, child | solid fallback |
| `KButton` | label, icon?, onPressed?, kind (primary/tonal/text/danger), size (48/40) | disabled = 40 % opacity + semantics disabled |
| `KChip` | label, icon?, selected, onTap | 32–36 h; selected = accent 14 % + 1.5 ring |
| `KSegment<T>` | items, value, onChanged, height (40/44) | selected pill |
| `KField` | label, value/controller, prefix, suffix, state (normal/active/error/warning), helper | 56 h r14 |
| `KSwitch` / `KCheck` / `KRadio` | value, onChanged, semanticLabel | 52×32 / 22 / 20 |
| `KProgress` | value 0..1+, tone (accent/warning/danger) | 6 px |
| `ListGroup` | children, divider inset | card r16 |
| `TxRow` | transaction, onTap | 64 h; title wraps at large text; amount FittedBox |
| `NavRow` | icon, title, subtitle?, trailingText?, trailing (chevron/switch/button) | ≥ 52 h |
| `CategoryIcon` | iconKey, color, size (28/32/36/40/48/64) | round fill 14 %/12 % |
| `BalanceHero` | label, amount, rows, insight? | GlassCard ultra |
| `StatTiles` | items [{value, label, tone}] | success/neutral/danger |
| `KBottomNav` | index, onTap, onCatat | 84 h glass reguler, center Catat 52 px raised 12 |
| `Keypad` | onKey, saveEnabled, onSave, rowHeight (52/56) | 5×4, Simpan spans rows 2–4 |
| `AppFeedback.undo` | message, onUndo, duration=5s | glass tebal + 3 px progress |
| `AppFeedback.toast` | icon, title, body, actions[] | glass tebal r16 |
| `AppFeedback.confirm` | icon?, title, body, infoBox?, safeAction, dangerAction?, cancel | scrim 55 %, safe = primary |
| `EmptyState` | icon, title, body, action? | centered |
| `StepHeader` | step, total, label | 3-segment progress |

Accessibility: every icon-only control has a `Semantics` label matching the board's
`aria-label` (e.g. "Cari transaksi", "Tukar rekening asal dan tujuan"); touch targets ≥ 44 px.
