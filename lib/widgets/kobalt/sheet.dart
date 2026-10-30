import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Opens a bottom sheet on the themed card surface. `Get.bottomSheet`
/// defaults its background to transparent (ignoring `bottomSheetTheme`),
/// which left sheets floating with unreadable titles on the light theme —
/// so every sheet goes through here.
Future<T?> showSheet<T>(Widget child, {bool isScrollControlled = false}) =>
    Get.bottomSheet<T>(
      child,
      backgroundColor: colorCard,
      isScrollControlled: isScrollControlled,
    );
