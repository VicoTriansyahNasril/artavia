import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/core/database/dummy_data.dart';
import 'package:artavia/widgets/components/tutorial_card.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
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

    totalAccounts.value = accounts.length;
    totalCategories.value = categories.length;
    netWorth.value = computeNetWorth(accounts).net;
  }

  Future<void> connectGoogleDrive() async {
    final driveService = Get.find<GoogleDriveService>();
    if (driveService.isConnecting.value || driveService.isWorking.value) return;
    final success = await driveService.signIn();
    if (success) {
      AppToast.success('Berhasil', 'Terhubung ke Google Drive');
    } else {
      AppToast.error('Gagal', 'Tidak dapat terhubung ke Google Drive');
    }
  }

  Future<void> disconnectGoogleDrive() async {
    final driveService = Get.find<GoogleDriveService>();
    if (driveService.isConnecting.value || driveService.isWorking.value) return;
    await driveService.signOut();
    AppToast.info('Terputus', 'Akun Google Drive telah diputuskan');
  }

  Future<void> backupData() async {
    final driveService = Get.find<GoogleDriveService>();
    if (driveService.isConnecting.value || driveService.isWorking.value) return;
    try {
      AppDialog.showProgress();
      await driveService.backupDatabase();
      AppDialog.hideProgress();
      AppToast.success(
          'Backup Berhasil', 'Data berhasil diunggah ke Google Drive');
    } catch (e) {
      AppDialog.hideProgress();
      AppToast.error('Backup Gagal', e.toString());
    }
  }

  Future<void> restoreData() async {
    final driveService = Get.find<GoogleDriveService>();
    if (driveService.isConnecting.value || driveService.isWorking.value) return;
    try {
      AppDialog.showProgress();
      await driveService.restoreDatabase();

      // The restored DB carries its own settings (format, PIN, month start).
      await SettingsService.to.reload();
      PeriodService.to.resetToToday();
      refreshAllGlobalData();

      AppDialog.hideProgress();
      AppToast.success(
          'Restore Berhasil', 'Data berhasil dipulihkan dari Google Drive');
    } catch (e) {
      AppDialog.hideProgress();
      AppToast.error('Restore Gagal', e.toString());
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
                description:
                    "Pilih menu Mengelola Rekening untuk membuat rekening atau dompet pertama Anda.",
                isLast: true,
              );
            },
          )
        ],
      )
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: colorScrim,
      hideSkip: true,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        Get.toNamed(accountManagementRoute);
        Future.delayed(const Duration(milliseconds: 400), () {
          Get.find<AccountManagementController>().showTutorialIfNoAccount();
        });
      },
      onClickTarget: (target) {
        Get.toNamed(accountManagementRoute);
        Future.delayed(const Duration(milliseconds: 400), () {
          Get.find<AccountManagementController>().showTutorialIfNoAccount();
        });
      },
    ).show(context: keyProfileManageAccounts.currentContext!);
  }

  Future<void> generateDummyData() async {
    try {
      AppDialog.showProgress();
      final db = await DatabaseHelper.instance.database;
      await DummyDataGenerator.generate(db);

      refreshAllGlobalData();

      AppDialog.hideProgress();
      AppToast.success('Berhasil', 'Data dummy berhasil ditambahkan');
    } catch (e) {
      AppDialog.hideProgress();
      AppToast.error('Gagal', e.toString());
    }
  }
}
