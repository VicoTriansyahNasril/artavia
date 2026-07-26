import 'package:flutter/material.dart';

import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:get/get.dart';
import 'package:artavia/page/home/home_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dailyReminder = false;
  bool _soundEffect = false;
  bool _appLock = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = DatabaseHelper.instance;
    final reminder = await db.getSetting('daily_reminder');
    final sound = await db.getSetting('sound_effect');
    final lock = await db.getSetting('app_lock');
    setState(() {
      _dailyReminder = reminder == 'true';
      _soundEffect = sound == 'true';
      _appLock = lock == 'true';
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    await DatabaseHelper.instance.saveSetting(key, value.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: colorBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        title: const Text('Pengaturan Lainnya',
            style: TextStyle(color: colorWhite, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              title: 'Otomatisasi & Utilitas',
              children: [
                _buildSwitchItem(
                  Icons.notifications,
                  'Pengingat Harian',
                  _dailyReminder,
                  (val) {
                    setState(() => _dailyReminder = val);
                    _saveSetting('daily_reminder', val);
                  },
                ),
                const Divider(color: colorBackground, height: 1),
                _buildListItem(Icons.repeat, 'Transaksi Berulang'),
                const Divider(color: colorBackground, height: 1),
                _buildListItem(Icons.date_range, 'Mulai Bulan Pada',
                    trailingText: 'Tanggal 1'),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Keamanan & Data',
              children: [
                _buildSwitchItem(
                  Icons.lock,
                  'Kunci Aplikasi (PIN)',
                  _appLock,
                  (val) {
                    setState(() => _appLock = val);
                    _saveSetting('app_lock', val);
                  },
                ),
                const Divider(color: colorBackground, height: 1),
                _buildListItem(Icons.cloud_upload, 'Cadangkan Data'),
                const Divider(color: colorBackground, height: 1),
                _buildListItem(
                    Icons.import_export, 'Ekspor / Impor (Excel/CSV)'),
                const Divider(color: colorBackground, height: 1),
                _buildListItem(Icons.delete_forever, 'Reset Seluruh Data',
                    textColor: colorExpense,
                    onTap: _confirmResetData),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Personalisasi',
              children: [
                _buildListItem(Icons.format_list_numbered, 'Format Angka',
                    trailingText: '1.000'),
                const Divider(color: colorBackground, height: 1),
                _buildSwitchItem(
                  Icons.volume_up,
                  'Efek Suara',
                  _soundEffect,
                  (val) {
                    setState(() => _soundEffect = val);
                    _saveSetting('sound_effect', val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _confirmResetData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorCard,
        title: const Text('Reset Seluruh Data',
            style: TextStyle(color: colorWhite, fontWeight: FontWeight.bold)),
        content: const Text(
          'Semua transaksi, rekening, dan kategori kustom akan dihapus permanen. '
          'Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: colorGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: colorGrey)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: colorExpense),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              await DatabaseHelper.instance.resetDatabase();
              
              // Give some time and reload settings
              await _loadSettings();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua data berhasil direset'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              
              if (Get.isRegistered<HomeController>()) {
                Get.find<HomeController>().loadData();
              }
            },
            child: const Text('Reset',
                style: TextStyle(color: colorWhite)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
                color: colorGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1),
          ),
        ),
        Container(
          color: colorCard,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListItem(IconData icon, String title,
      {String? trailingText,
      Color textColor = colorWhite,
      VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: colorGrey),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText,
                style: const TextStyle(color: colorGrey)),
          if (trailingText != null) const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: colorGrey),
        ],
      ),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildSwitchItem(IconData icon, String title, bool value,
      ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: colorGrey),
      title: Text(title, style: const TextStyle(color: colorWhite)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: colorAccent,
      ),
    );
  }
}
