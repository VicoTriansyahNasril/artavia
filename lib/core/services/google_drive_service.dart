import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

/// Google sign-in and an authorized Drive client — nothing else. Backups
/// live in `BackupService` (research R10).
///
/// Scopes: `drive.appdata` (Artavia's hidden folder) plus `drive.file`,
/// which only reaches files Artavia created itself — needed to read a legacy
/// `artavia_backup.db` from before v12.
class GoogleDriveService extends GetxService {
  static GoogleDriveService get to => Get.find();

  /// OAuth "Web application" client ID from Google Cloud Console (same
  /// project as the Android client for `id.artavia.app` + the signing
  /// SHA-1s). Android needs nothing else. See docs/google-drive-android.md.
  static const webClientId =
      '591973850664-773205kiaqtdd2hr44lfbhnq5gm8pl37.apps.googleusercontent.com';

  /// False until [webClientId] is filled in; sign-in cannot work before.
  static bool get isConfigured => !webClientId.startsWith('GANTI_');

  static const scopes = [
    drive.DriveApi.driveAppdataScope,
    drive.DriveApi.driveFileScope,
  ];

  sign_in.GoogleSignInAccount? _user;
  drive.DriveApi? _api;

  final isConnecting = false.obs;
  final isConnected = false.obs;
  final email = RxnString();

  /// Google profile shown on the Cadangan screen once connected.
  final displayName = RxnString();
  final photoUrl = RxnString();

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    if (!isConfigured) return;
    try {
      await sign_in.GoogleSignIn.instance.initialize(
        serverClientId: webClientId,
      );
      sign_in.GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is sign_in.GoogleSignInAuthenticationEventSignIn) {
          _setUser(event.user);
        } else if (event is sign_in.GoogleSignInAuthenticationEventSignOut) {
          _setUser(null);
        }
      });
      await sign_in.GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (e) {
      developer.log('Google sign-in init: $e', name: 'GoogleDriveService');
    }
  }

  void _setUser(sign_in.GoogleSignInAccount? user) {
    _user = user;
    if (user == null) _api = null;
    isConnected.value = user != null;
    email.value = user?.email;
    displayName.value = user?.displayName;
    photoUrl.value = user?.photoUrl;
  }

  /// Interactive sign-in with the backup scopes.
  Future<bool> connect() async {
    if (isConnecting.value) return false;
    isConnecting.value = true;
    try {
      final user =
          await sign_in.GoogleSignIn.instance.authenticate(scopeHint: scopes);
      _setUser(user);
      return await api(prompt: true) != null;
    } catch (e) {
      developer.log('Google sign-in: $e', name: 'GoogleDriveService');
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> disconnect() async {
    try {
      await sign_in.GoogleSignIn.instance.disconnect();
    } finally {
      _setUser(null);
    }
  }

  /// Authorized Drive client, or null when not signed in / not authorized.
  /// [prompt] may show the consent screen (only from a user action).
  Future<drive.DriveApi?> api({bool prompt = false}) async {
    if (_api != null) return _api;
    final user = _user;
    if (user == null) return null;
    try {
      final headers = await sign_in.GoogleSignIn.instance.authorizationClient
          .authorizationHeaders(scopes, promptIfNecessary: prompt);
      if (headers == null) return null;
      return _api = drive.DriveApi(GoogleAuthClient(headers));
    } catch (e) {
      developer.log('Drive authorization: $e', name: 'GoogleDriveService');
      return null;
    }
  }
}
