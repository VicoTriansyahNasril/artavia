# Backup Google Drive — Android (dibagikan lewat APK)

Aplikasi: `id.artavia.app`. Scope: `drive.appdata` + `drive.file` (keduanya
*non-sensitive*: tanpa verifikasi Google, tanpa layar "aplikasi belum
diverifikasi"). Tidak perlu Play Store.

## Sidik jari (SHA-1)

| Kunci | SHA-1 |
|---|---|
| Rilis (`android/upload-keystore.jks`, alias `upload`) | `E7:20:3A:BA:F9:8F:32:12:1F:86:CB:93:43:73:8D:29:55:27:21:28` |
| Debug (`~/.android/debug.keystore`, untuk `flutter run`) | `3C:39:8B:C5:70:5A:74:10:F7:B7:80:12:84:86:92:F3:D3:72:65:DF` |

`android/upload-keystore.jks` dan `android/key.properties` (berisi password)
tidak masuk git. **Backup keduanya.** Update APK wajib ditandatangani kunci
yang sama; jika berbeda, pengguna harus uninstall dulu dan data lokalnya
hilang.

## Google Cloud Console (sekali saja)

1. Buat project: https://console.cloud.google.com/projectcreate
2. Aktifkan Drive API:
   https://console.cloud.google.com/apis/library/drive.googleapis.com → **Enable**
3. Google Auth Platform → **Get started**:
   https://console.cloud.google.com/auth/overview
   - App name `Artavia`, support email; **Audience: External**; contact email;
     setujui kebijakan → **Create**. Jangan unggah logo (logo mewajibkan
     verifikasi brand).
4. **Data access** → *Add or remove scopes*:
   https://console.cloud.google.com/auth/scopes
   - `https://www.googleapis.com/auth/drive.appdata`
   - `https://www.googleapis.com/auth/drive.file` → **Save**
5. **Clients** → *Create client*: https://console.cloud.google.com/auth/clients
   - *Android* — package `id.artavia.app`, SHA-1 rilis.
   - *Android* — package `id.artavia.app`, SHA-1 debug.
   - *Web application* — salin **Client ID**-nya.
6. **Branding**: homepage `https://vicotriansyahnasril.github.io/artavia/`,
   privacy policy `https://vicotriansyahnasril.github.io/artavia/privacy.html`,
   authorized domain `vicotriansyahnasril.github.io` (sumber: branch
   `gh-pages`). Lalu **Audience** → **Publish app** → status *In production*:
   https://console.cloud.google.com/auth/audience
   (Selama *Testing*: hanya test user, maks. 100, dan izin habis tiap 7 hari.)
7. `GoogleDriveService.webClientId` di
   `lib/core/services/google_drive_service.dart` = Web client ID
   (`591973850664-7732…`, sudah terpasang). Build: `flutter build apk --release`.
   Tidak ada `google-services.json`.
