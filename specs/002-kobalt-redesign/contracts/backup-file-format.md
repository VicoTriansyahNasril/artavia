# Backup File Format `.artv` v1

```
offset  size  field
0       5     magic "ARTV1"
5       4     header length N (uint32 big-endian)
9       N     header JSON (UTF-8)
9+N     …     payload
```

Header JSON:

```json
{
  "v": 1,
  "createdAt": "2026-10-27T08:00:00+07:00",
  "device": "Android",
  "txCount": 1248,
  "accountCount": 7,
  "dbVersion": 12,
  "locked": true,
  "hint": "nama kucing pertama",
  "kdf": {"alg": "PBKDF2-HMAC-SHA256", "iter": 210000, "salt": "<base64 16B>"},
  "cipher": {"alg": "AES-256-GCM", "nonce": "<base64 12B>"}
}
```

- `locked: false` → payload is the raw SQLite file; `kdf`/`cipher` omitted.
- `locked: true` → payload = ciphertext ‖ 16-byte GCM tag of the SQLite file.
- The same non-secret fields are mirrored into Drive `appProperties`
  (`createdAt, device, txCount, accountCount, locked, hint`) for listing.
- Restore: decrypt → write temp file → `PRAGMA integrity_check` = ok → close DB → replace
  `artavia.db` → reopen (runs `onUpgrade` if `dbVersion` < current) → `refreshAllGlobalData()`.
- Any failure in decrypt/tag check reports only "Kata sandi salah" (no detail).
- Legacy plain `artavia_backup.db` (pre-v12 scope) is accepted as `locked: false`, v0.
