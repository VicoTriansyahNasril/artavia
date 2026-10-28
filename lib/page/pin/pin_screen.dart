import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/page/pin/pin_controller.dart';
import 'package:artavia/page/pin/pin_pad.dart';

/// Create a PIN (argument `mode: 'setup'`) or confirm it to turn the lock off
/// (`mode: 'disable'`). Returns `true` via Get.back when it succeeded.
class PinScreen extends GetView<PinController> {
  const PinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(controller.isSetup ? 'Buat PIN' : 'Nonaktifkan PIN')),
      body: SafeArea(
        child: Center(
          child: Obx(() => PinPad(
                key: ValueKey(controller.step.value),
                title: controller.title,
                message: controller.message.value,
                isError: controller.isError.value,
                busy: controller.busy.value,
                onCompleted: controller.onPinEntered,
              )),
        ),
      ),
    );
  }
}
