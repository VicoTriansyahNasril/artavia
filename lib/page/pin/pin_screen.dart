import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/page/pin/pin_controller.dart';
import 'package:artavia/page/pin/pin_pad.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Create a PIN (argument `mode: 'setup'`) or confirm it to turn the lock off
/// (`mode: 'disable'`). Returns `true` via Get.back when it succeeded.
class PinScreen extends GetView<PinController> {
  const PinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.close,
      centeredOrb: true,
      body: Center(
        child: SingleChildScrollView(
          child: Obx(() => PinPad(
                key: ValueKey(controller.step.value),
                title: controller.title,
                length: controller.length,
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
