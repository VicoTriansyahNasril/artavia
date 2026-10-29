import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Action button shown inside a toast (e.g. "Tutup", "Coba lagi").
class ToastAction {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const ToastAction(this.label, this.onTap, {this.primary = false});
}

/// One look for every toast/snackbar (Kobalt glass tebal), one at a time,
/// floating above the bottom navigation.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;
  static String? _currentKey;

  static void success(String title, String message) => toast(
      icon: LucideIcons.circleCheck,
      tone: colorIncome,
      title: title,
      body: message);

  static void info(String title, String message) => toast(
      icon: LucideIcons.info, tone: colorAccent, title: title, body: message);

  /// Validation-style warnings are de-duplicated so repeated taps don't stack.
  static void warning(String title, String message) {
    if (_currentKey == 'warning:$title') return;
    toast(
        icon: LucideIcons.triangleAlert,
        tone: colorWarning,
        title: title,
        body: message,
        dedupeKey: 'warning:$title');
  }

  static void error(String title, String message) => toast(
      icon: LucideIcons.circleAlert,
      tone: colorDanger,
      title: title,
      body: message,
      duration: const Duration(seconds: 4));

  /// Board "Toast": 36 px tinted icon, title + description, optional actions.
  static void toast({
    required IconData icon,
    required Color tone,
    required String title,
    String? body,
    List<ToastAction> actions = const [],
    Duration duration = const Duration(milliseconds: 2500),
    String? dedupeKey,
  }) {
    _show(
      dedupeKey,
      actions.isEmpty ? duration : const Duration(seconds: 6),
      (close) => _ToastCard(
        icon: icon,
        tone: tone,
        title: title,
        body: body,
        actions: [
          for (final a in actions)
            ToastAction(a.label, () {
              close();
              a.onTap();
            }, primary: a.primary),
        ],
      ),
    );
  }

  /// Board "Hapus + Urungkan": message, "Urungkan" tonal button and a 3 px
  /// bar counting down [duration]. [onUndo] runs only if tapped in time.
  static void undo(String message,
      {required VoidCallback onUndo,
      Duration duration = const Duration(seconds: 5)}) {
    _show(
      null,
      duration,
      (close) => _UndoBar(
        message: message,
        duration: duration,
        onUndo: () {
          close();
          onUndo();
        },
      ),
    );
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
    _currentKey = null;
  }

  static void _show(String? key, Duration duration,
      Widget Function(VoidCallback close) builder) {
    final overlay = Get.key.currentState?.overlay;
    if (overlay == null) return;
    dismiss();
    _currentKey = key;
    late final OverlayEntry entry;
    void close() {
      if (identical(_entry, entry)) dismiss();
    }

    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 92,
        child: _SlideIn(
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.down,
            onDismissed: (_) => close(),
            child: builder(close),
          ),
        ),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, close);
  }
}

class _SlideIn extends StatelessWidget {
  final Widget child;
  const _SlideIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

class _ToastCard extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final String title;
  final String? body;
  final List<ToastAction> actions;

  const _ToastCard({
    required this.icon,
    required this.tone,
    required this.title,
    this.body,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        liveRegion: true,
        child: GlassCard(
          level: GlassLevel.thick,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: softFill(tone), shape: BoxShape.circle),
                    child: Icon(icon, size: 18, color: tone),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppText.bodySmall.w600
                                .copyWith(color: colorText)),
                        if (body != null && body!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(body!, style: AppText.caption.onGlass),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final a in actions)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: a.primary
                              ? KButton.tonal(
                                  label: a.label, onPressed: a.onTap)
                              : KButton.text(
                                  label: a.label,
                                  onPressed: a.onTap,
                                  compact: true,
                                  expand: false),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UndoBar extends StatelessWidget {
  final String message;
  final Duration duration;
  final VoidCallback onUndo;

  const _UndoBar(
      {required this.message, required this.duration, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        liveRegion: true,
        child: GlassCard(
          level: GlassLevel.thick,
          borderRadius: BorderRadius.circular(14),
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(message,
                          style: AppText.bodySmall.copyWith(color: colorText)),
                    ),
                    KButton.tonal(label: 'Urungkan', onPressed: onUndo),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: duration,
                builder: (context, v, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: v,
                    child: Container(height: 3, color: colorAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum DialogChoice { safe, danger, cancel }

/// Tinted note inside a dialog (accent or warning, 14 %).
class DialogInfo {
  final String text;
  final bool warning;
  const DialogInfo(this.text, {this.warning = false});
}

/// One look for every confirmation dialog (scrim 55 %, glass r20).
class AppDialog {
  AppDialog._();

  /// Returns `true` when the user confirmed. With [destructive] the confirm
  /// action is the danger-outline button and [safeLabel] (if given) becomes
  /// the primary button that also returns `false`.
  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    bool destructive = false,
    IconData? icon,
    DialogInfo? info,
    String? safeLabel,
  }) async {
    final tone = destructive ? colorDanger : colorAccent;
    final result = await Get.dialog<bool>(
      _KDialog(
        icon: icon,
        tone: tone,
        title: title,
        message: message,
        info: info,
        actions: [
          if (destructive && safeLabel != null)
            KButton(label: safeLabel, onPressed: () => Get.back(result: false)),
          if (destructive)
            KButton.danger(
                label: confirmLabel, onPressed: () => Get.back(result: true))
          else
            KButton(
                label: confirmLabel, onPressed: () => Get.back(result: true)),
          KButton.text(
              label: cancelLabel, onPressed: () => Get.back(result: false)),
        ],
      ),
      barrierColor: colorScrim,
    );
    return result ?? false;
  }

  /// Three-way dialog: safe action (primary), destructive action (danger
  /// outline) and cancel. Used for "Arsipkan / Hapus beserta N / Batal".
  static Future<DialogChoice> choose({
    required String title,
    required String message,
    required String safeLabel,
    required String dangerLabel,
    String cancelLabel = 'Batal',
    IconData? icon,
    DialogInfo? info,
  }) async {
    final result = await Get.dialog<DialogChoice>(
      _KDialog(
        icon: icon,
        tone: colorDanger,
        title: title,
        message: message,
        info: info,
        actions: [
          KButton(
              label: safeLabel,
              onPressed: () => Get.back(result: DialogChoice.safe)),
          KButton.danger(
              label: dangerLabel,
              onPressed: () => Get.back(result: DialogChoice.danger)),
          KButton.text(
              label: cancelLabel,
              onPressed: () => Get.back(result: DialogChoice.cancel)),
        ],
      ),
      barrierColor: colorScrim,
    );
    return result ?? DialogChoice.cancel;
  }

  /// Information only: one "Tutup" button.
  static Future<void> info({
    required String title,
    required String message,
    IconData? icon,
    String closeLabel = 'Tutup',
  }) {
    return Get.dialog<void>(
      _KDialog(
        icon: icon,
        tone: colorAccent,
        title: title,
        message: message,
        actions: [KButton(label: closeLabel, onPressed: Get.back)],
      ),
      barrierColor: colorScrim,
    );
  }

  /// Blocking spinner for long operations; close with [hideProgress].
  static void showProgress() {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
      barrierColor: colorScrim,
    );
  }

  static void hideProgress() {
    if (Get.isDialogOpen ?? false) Get.back();
  }
}

class _KDialog extends StatelessWidget {
  final IconData? icon;
  final Color tone;
  final String title;
  final String message;
  final DialogInfo? info;
  final List<Widget> actions;

  const _KDialog({
    this.icon,
    required this.tone,
    required this.title,
    required this.message,
    this.info,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            type: MaterialType.transparency,
            child: GlassCard(
              level: GlassLevel.thick,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (icon != null) ...[
                      Align(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: softFill(tone), shape: BoxShape.circle),
                          child: Icon(icon, size: 24, color: tone),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(title,
                        textAlign:
                            icon != null ? TextAlign.center : TextAlign.start,
                        style: AppText.title3
                            .copyWith(fontSize: 18, color: colorText)),
                    const SizedBox(height: 8),
                    Text(message,
                        textAlign:
                            icon != null ? TextAlign.center : TextAlign.start,
                        style: AppText.bodySmall.onGlass),
                    if (info != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: softFill(
                              info!.warning ? colorWarning : colorAccent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(info!.text,
                            style: AppText.caption.copyWith(
                                color: info!.warning
                                    ? colorWarning
                                    : colorAccent)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
