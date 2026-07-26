import 'dart:io';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService extends GetxService {
  sign_in.GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  final RxBool isConnecting = false.obs;
  final RxBool isConnected = false.obs;
  final RxBool isWorking = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initDrive();
  }

  Future<void> _initDrive() async {
    try {
      await sign_in.GoogleSignIn.instance.initialize(
        serverClientId: 'GANTI_DENGAN_WEB_CLIENT_ID_ANDA.apps.googleusercontent.com',
      );
      sign_in.GoogleSignIn.instance.authenticationEvents.listen((sign_in.GoogleSignInAuthenticationEvent event) {
        if (event is sign_in.GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          isConnected.value = true;
        } else if (event is sign_in.GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          isConnected.value = false;
        }
      });
      await sign_in.GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (e) {
      developer.log('Google Drive Init Error: $e', name: 'GoogleDriveService');
    }
  }

  Future<bool> signIn() async {
    if (isConnecting.value || isWorking.value) return false;
    isConnecting.value = true;
    try {
      _currentUser = await sign_in.GoogleSignIn.instance.authenticate(
        scopeHint: [drive.DriveApi.driveFileScope]
      );
      if (_currentUser != null) {
        final headers = await sign_in.GoogleSignIn.instance.authorizationClient.authorizationHeaders(
          [drive.DriveApi.driveFileScope],
          promptIfNecessary: true,
        );
        if (headers != null) {
          final authenticateClient = GoogleAuthClient(headers);
          _driveApi = drive.DriveApi(authenticateClient);
          isConnected.value = true;
          return true;
        }
      }
    } catch (e) {
      // Ignored print
    } finally {
      isConnecting.value = false;
    }
    return false;
  }

  Future<void> signOut() async {
    if (isConnecting.value || isWorking.value) return;
    isConnecting.value = true;
    try {
      await sign_in.GoogleSignIn.instance.disconnect();
      _currentUser = null;
      _driveApi = null;
      isConnected.value = false;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> backupDatabase() async {
    if (isWorking.value) return;
    isWorking.value = true;
    
    try {
      if (_driveApi == null) {
        final success = await signIn();
        if (!success) throw Exception('Google Sign-In required');
      }
      final dbPath = await getDatabasesPath();
      final localDbFile = File(p.join(dbPath, 'artavia.db'));

      if (!localDbFile.existsSync()) {
        throw Exception('Database lokal tidak ditemukan.');
      }

      // Check if backup already exists
      const q = "name = 'artavia_backup.db' and trashed = false";
      final fileList = await _driveApi!.files.list(q: q, spaces: 'drive');

      final media = drive.Media(localDbFile.openRead(), localDbFile.lengthSync());
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file
        final fileId = fileList.files!.first.id!;
        final driveFile = drive.File();
        await _driveApi!.files.update(
          driveFile,
          fileId,
          uploadMedia: media,
        );
      } else {
        // Create new file
        final driveFile = drive.File()
          ..name = 'artavia_backup.db'
          ..description = 'Artavia App Database Backup';
        await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
      }
    } catch (e) {
      throw Exception('Gagal melakukan backup: $e');
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> restoreDatabase() async {
    if (isWorking.value) return;
    isWorking.value = true;

    try {
      if (_driveApi == null) {
        final success = await signIn();
        if (!success) throw Exception('Google Sign-In required');
      }
      const q = "name = 'artavia_backup.db' and trashed = false";
      final fileList = await _driveApi!.files.list(q: q, spaces: 'drive');

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('File backup tidak ditemukan di Google Drive Anda.');
      }

      final fileId = fileList.files!.first.id!;
      
      // We actually need to download the file contents:
      final fullMedia = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dbPath = await getDatabasesPath();
      final restorePath = p.join(dbPath, 'artavia.db');
      final localDbFile = File(restorePath);

      final List<int> dataStore = [];
      await fullMedia.stream.listen((data) {
        dataStore.insertAll(dataStore.length, data);
      }).asFuture();

      await localDbFile.writeAsBytes(dataStore, flush: true);

    } catch (e) {
      throw Exception('Gagal memulihkan backup: $e');
    } finally {
      isWorking.value = false;
    }
  }
}
