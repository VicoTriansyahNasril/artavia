import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';

class ProfileController extends GetxController {
  final userName = 'Pengguna Artavia'.obs;
  final totalAccounts = 0.obs;
  final totalCategories = 0.obs;
  final netWorth = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    final accounts = await DatabaseHelper.instance.readAllAccounts();
    final categories = await DatabaseHelper.instance.readAllCategories();

    int nw = 0;
    for (final acc in accounts) {
      final excluded = acc['is_excluded'] == 1;
      if (!excluded) {
        nw += acc['balance'] as int;
      }
    }

    totalAccounts.value = accounts.length;
    totalCategories.value = categories.length;
    netWorth.value = nw;
  }

  Future<void> connectGoogleDrive() async {
    final driveService = Get.find<GoogleDriveService>();
    if (driveService.isConnecting.value || driveService.isWorking.value) return;
    final success = await driveService.signIn();
    if (success) {
      Get.snackbar('Berhasil', 'Terhubung ke Google Drive');
    } else {
      Get.snackbar('Gagal', 'Tidak dapat terhubung ke Google Drive');
    }
  }

  Future<void> disconnectGoogleDrive() async {
    final driveService = Get.find<GoogleDriveService>();
    if (driveService.isConnecting.value || driveService.isWorking.value) return;
    await driveService.signOut();
    Get.snackbar('Terputus', 'Akun Google Drive telah diputuskan');
  }

  Future<void> backupData() async {
    final driveService = Get.find<GoogleDriveService>();
    if (driveService.isConnecting.value || driveService.isWorking.value) return;
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      await driveService.backupDatabase();
      Get.back();
      Get.snackbar(
        'Backup Berhasil', 
        'Data berhasil diunggah ke Google Drive',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Backup Gagal', 
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> restoreData() async {
    final driveService = Get.find<GoogleDriveService>();
    if (driveService.isConnecting.value || driveService.isWorking.value) return;
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      await driveService.restoreDatabase();
      
      // Reload everything in memory
      refreshAllGlobalData();
      loadStats();

      Get.back();
      Get.snackbar(
        'Restore Berhasil', 
        'Data berhasil dipulihkan dari Google Drive',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Restore Gagal', 
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
