# Kobalt Design Digest

Extracted verbatim from the HTML exports attached in the session
(`komponen.html`, `layar-1.html`, `layar-2.html`, `layar-3.html`, 2026-10-29).
The HTML files themselves were pasted inline and are not stored here (each
embeds ~200 KB of base64 font data). The PNG boards in this folder are the
visual reference. Values not present in the source are marked
`[not specified in source]`.

## 1. Foundation tokens

### Font
- Family: **Plus Jakarta Sans**, weights 400 / 500 / 600 / 700.
- `font-variant-numeric: tabular-nums` on every screen with amounts.
- Minus sign is U+2212 (`−`), not hyphen.

### Type scale (size / line-height, weight)
| Role | Size/LH | Weight | Example |
|---|---|---|---|
| Display | 34/40 (screens use 28/34 for balances, 36/44 for entry amount) | 700, letter-spacing −0.5 | Rp 3.284.500 |
| Judul 1 | 22/28 | 700 | Cadangan ditemukan |
| Judul 2 | 20/26 | 600 | Pengaturan (screen title) |
| Judul 3 | 16/22 | 600 | Biaya admin / modal header |
| Isi | 15/20 | 400 | list title |
| Isi kecil | 14/20 | 400 | body copy |
| Label | 13/18 | 600 | chips, segment, section action |
| Keterangan | 12/16 | 400 | minimum text size in the app |

"Rp" prefix next to big amounts: 17/22 weight 500 in secondary text color.

### Colors — dark (default)
| Token | Hex |
|---|---|
| Latar (background) | #111318 |
| Kartu (card) | #181B21 |
| Permukaan (surface / input / chip) | #20242C |
| Garis (divider) | #2A2F38 |
| Teks | #E7E9EE |
| Teks redup | #8D94A3 |
| Teks sekunder di atas kaca | #A3AAB8 |
| Aksen | #5B8CFF |
| Aksen lembut (14 %) | rgba(91,140,255,0.14) |
| Teks di atas aksen | #0B1020 |
| Pemasukan | #5FBF8F |
| Bahaya / pengeluaran-error | #E07A7A |
| Peringatan | #E0B25C |
| Segmen terpilih | #2E333D |
| Tombol operator papan angka | #262B34 |
| Saklar mati (track) | #3A404B |
| Scrim dialog | rgba(0,0,0,0.55) |

### Colors — light
| Token | Hex |
|---|---|
| Latar | #F5F6F8 |
| Kartu | #FFFFFF (shadow 0 1 2 rgba(27,30,36,.05), 0 4 12 rgba(27,30,36,.04)) |
| Permukaan | #EEF0F4 |
| Garis | #E3E6EB |
| Teks | #1B1E24 |
| Teks redup | #5D6472 |
| Teks sekunder di atas kaca | #4E5563 |
| Aksen | #2557D6 |
| Aksen lembut (10 %) | rgba(37,87,214,0.10) |
| Teks di atas aksen | #FFFFFF |
| Pemasukan | #1F8657 |
| Bahaya | #C2453F |
| Peringatan | #A86E12 |
| Segmen terpilih | #FFFFFF + shadow 0 1 3 rgba(27,30,36,.12) |
| Saklar mati (track) | #C9CED6 |

### Category palette (12) — dark / light
| Name (ID) | Dark | Light |
|---|---|---|
| Coral (Koral) | #E07A7A | #C95A5A |
| Apricot (Aprikot) | #E59A6B | #C2703E |
| Sand (Pasir) | #E0B25C | #A87B1E |
| Olive (Zaitun) | #A3BE6C | #6E8A3A |
| Mint | #5FBF8F | #2E9466 |
| Teal | #4FB6B0 | #24857F |
| Sky (Langit) | #5FA8D3 | #2F7BAA |
| Blue (Biru) | #5B8CFF | #2557D6 |
| Lavender | #9D8CE6 | #6F5CCF |
| Orchid (Anggrek) | #C987C9 | #A0569F |
| Rose (Mawar) | #D98AA8 | #B4587C |
| Slate (Batu) | #8D94A3 | #6A7180 |

Soft fill: category color at 14 % alpha (dark) / 12 % (light).

### Shape & spacing
- Radius scale: 8, 10, 12, 14, 16, 20, full (999).
  - Keypad keys / small inputs 10; buttons & segment 12; amount field 14;
    list groups 16; glass hero cards & dialogs 20; bottom sheet top 24; device frame 32.
- Spacing: multiples of 4 (4, 8, 12, 16, 24, 32). Screen padding 12 top / 16 sides.
- Minimum touch target 44 px. List rows ≥ 52 px (transaction rows 64 px).

### Glass layers (backdrop blur 20–40 px, saturate 180 %)
| Layer | Dark bg | Light bg |
|---|---|---|
| Ultra (hero cards) | rgba(22,26,33,0.40) | rgba(255,255,255,0.40) |
| Tipis (bottom keypad sheet, sticky footer) | rgba(22,26,33,0.55) | rgba(255,255,255,0.55) |
| Reguler (bottom nav, footer CTA) | rgba(24,28,36,0.70) | rgba(255,255,255,0.70) |
| Tebal (snackbar, toast, dialog) | rgba(28,32,41,0.82–0.90) | [not specified in source] |
Border 1 px rgba(255,255,255,0.05) dark / rgba(11,13,18,0.06) light; inset top highlight
rgba(255,255,255,0.12) dark / 0.7 light; drop shadow 0 8 32 rgba(0,0,0,0.32) dark /
rgba(27,30,36,0.10) light.

"Kurangi transparansi" setting replaces glass with solid colors.

### Ambient orb
One per screen: 320 px circle, right −90 / top −80, accent at 30 % (dark) / 18 % (light),
blur 60 px. PIN screen centers it (360 px, 26 %).

## 2. Components
- **Tombol**: Utama (accent fill, 48 h, r12, 15/600), Tonal (accent 14 % fill, accent text, 40 h),
  Teks (transparent, accent), Bahaya (outline 1.5 px danger, danger text). Disabled = opacity 40 %.
  Catat FAB: 52 px circle accent, raised −12 px into the bottom nav.
- **Chip**: 32–36 h, full radius, surface bg; selected = accent 14 % + accent text + 1.5 px accent
  inset ring (+ optional check icon).
- **Segmen**: 40–44 h, r12 surface track, 4 px padding, selected pill #2E333D.
- **Kolom isian**: 56 h, r14, card bg; normal ring 1 px garis; aktif 1.5 px accent;
  error 1.5 px danger + 12 px danger helper; peringatan 1.5 px warning ring.
- **Saklar** 52×32, **Centang** 22 r6, **Radio** 20, **Kemajuan** 6 px full radius.
- **Baris daftar**: 40 px colored round icon, title 15, subtitle 12 redup
  (`Kategori · Rekening · jam`), amount 14/600 right; divider inset 68 px.
- **Kartu saldo (kaca)**: label 12, "Rp" 17/500 + amount 28/700, 2-col pemasukan/pengeluaran,
  insight row with trend icon separated by 1 px glass divider.
- **Angka ringkas**: 3 tiles (success 14 %, surface, danger 14 %), value 20/700.
- **Navigasi bawah**: 84 h glass reguler; 5 slots Transaksi · Laporan · [Catat] · Rekening ·
  Pengaturan; active item = accent text + 56×28 pill accent 14 %.
- **Snackbar**: glass tebal r14, message + "Urungkan" tonal button; 3 px progress bar showing
  remaining 5 s.
- **Toast**: glass tebal r16, 36 px tinted icon, title + description, optional actions
  (Tutup / Coba lagi).
- **Dialog**: scrim 55 %, glass r20, optional 48 px tinted icon, title 18/600, body 14,
  optional info box (accent or warning 14 %), safe action = primary button, destructive = danger
  outline, then text "Batal/Tutup".
- **Papan angka**: 5×4 grid, rows 52–56 h, gap 8; digits surface 22/600; operators (÷ × − +)
  and backspace on #262B34 in accent; C in redup; "000" key; Simpan spans rows 2–4 in col 5
  with check icon.

## 3. Category icons
107 Lucide line icons (24 px, ISC licence) in 13 groups — 71 base + 36 extra:
Makanan & minuman (8+5), Transportasi (7+2), Rumah & tagihan (8+5), Belanja & gaya hidup (8+2),
Kesehatan & olahraga (6+3), Hiburan & liburan (6+5), Pendidikan & kerja (5+3),
Keluarga & sosial (5+2), Keuangan & kewajiban (6+1), Pemasukan (7), Lainnya (5),
Usaha (4, new group), Digital (4, new group). Full name list: see board 01-komponen-ikon.png.

## 4. Screens (boards)
Transaksi (beranda) · Catat transaksi (+ menghitung, + error) · Transfer (admin tersimpan,
tanpa admin, isi sendiri, saldo kurang) · Detail transaksi · Cari (ada hasil, kosong-terakhir,
nihil) · Kalender · Laporan (Minggu/Bulan/Tahun, privasi) · Rekening (+ dialog hapus) ·
Anggaran (+ kosong) · Pengaturan (+ cadangan gagal) · Kategori · Kategori baru · Ukuran teks ·
Pengguna baru · Hapus + Urungkan · PIN salah · Google Drive (belum, terhubung, proses) ·
Pulihkan (HP baru, sandi salah) · Ekspor · Impor 1/2/3 · Riwayat impor (+ konfirmasi batal).
Most boards come in Gelap and Terang variants.
