import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/core/database/dummy_data.dart';
import 'package:artavia/widgets/components/tutorial_card.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class ProfileController extends GetxController {
  final userName = 'Pengguna Artavia'.obs;
  final totalAccounts = 0.obs;
  final totalCategories = 0.obs;
  final netWorth = 0.obs;

  final GlobalKey keyProfileManageAccounts = GlobalKey();

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

  bool _hasShownTutorial = false;

  Future<void> showTutorialIfNoAccount() async {
    if (_hasShownTutorial) return;
    final accounts = await DatabaseHelper.instance.readAllAccounts();
    if (accounts.isEmpty) {
      _hasShownTutorial = true;
      _showTutorial();
    }
  }

  void _showTutorial() {
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetManageAccounts",
        keyTarget: keyProfileManageAccounts,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return TutorialCard(
                controller: controller,
                title: "Manajemen Rekening",
                description: "Pilih menu Mengelola Rekening untuk membuat rekening atau dompet pertama Anda.",
                isLast: true,
              );
            },
          )
        ],
      )
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      hideSkip: true,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        Get.toNamed('/account-management');
        Future.delayed(const Duration(milliseconds: 400), () {
          Get.find<AccountManagementController>().showTutorialIfNoAccount();
        });
      },
      onClickTarget: (target) {
        Get.toNamed('/account-management');
        Future.delayed(const Duration(milliseconds: 400), () {
          Get.find<AccountManagementController>().showTutorialIfNoAccount();
        });
      },
    ).show(context: keyProfileManageAccounts.currentContext!);
  }

  Future<void> generateDummyData() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final db = await DatabaseHelper.instance.database;
      await DummyDataGenerator.generate(db);
      
      // Reload everything in memory
      refreshAllGlobalData();
      loadStats();

      Get.back();
      Get.snackbar(
        'Berhasil', 
        'Data dummy berhasil ditambahkan',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Gagal', 
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
