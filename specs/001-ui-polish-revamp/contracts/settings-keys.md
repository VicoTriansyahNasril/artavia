# Contract: Settings keys (`settings` table, string values)

| Key | Values | Default | Used by |
| --- | ------ | ------- | ------- |
| daily_reminder | `true`/`false` | `false` | NotificationService |
| reminder_time | `HH:mm` | `20:00` | NotificationService |
| month_start_day | `1`..`28` | `1` | PeriodService |
| app_lock | `true`/`false` | `false` | PinLockService |
| pin_salt | base64 | — | PinLockService |
| pin_hash | PBKDF2-SHA256 (600k) base64 | — | PinLockService |
| number_format | `dot`/`comma` | `dot` | CurrencyService |
| sound_effect | `true`/`false` | `false` | SoundService |

`SettingsService` loads all keys once at startup into memory (`RxMap`), writes through to the DB, and is the only reader/writer. `resetDatabase()` clears all keys; services re-read defaults afterwards (reminder cancelled, lock off).
