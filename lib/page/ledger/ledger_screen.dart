import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/page/ledger/ledger_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class LedgerScreen extends GetView<LedgerController> {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorBackground,
        title: const Text('Pilih Buku Kas', style: TextStyle(color: colorWhite, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: colorWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: controller.ledgers.length,
          itemBuilder: (context, index) {
            final ledger = controller.ledgers[index];
            final isSelected = controller.selectedLedgerId.value == ledger['id'];
            
            return Container(
              color: colorCard,
              margin: const EdgeInsets.only(bottom: 1),
              child: ListTile(
                onTap: () => controller.selectLedger(ledger['id'] as String),
                leading: CircleAvatar(
                  backgroundColor: isSelected ? colorAccent : colorBackground,
                  child: Icon(Icons.book, color: isSelected ? colorBlack : colorGrey),
                ),
                title: Text(ledger['name'] as String, style: const TextStyle(color: colorWhite, fontWeight: FontWeight.bold)),
                subtitle: ledger['isDefault'] as bool 
                    ? const Text('Bawaan', style: TextStyle(color: colorGrey, fontSize: 12)) 
                    : null,
                trailing: isSelected 
                    ? const Icon(Icons.check_circle, color: colorAccent) 
                    : const Icon(Icons.circle_outlined, color: colorGrey),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: colorAccent,
        child: const Icon(Icons.add, color: colorBlack),
      ),
    );
  }
}
