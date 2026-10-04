import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile, desktop;
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 700;
  static Duration duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 180);
  @override
  Widget build(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 1000 ? mobile : desktop;
}

Future<T?> showAdaptivePopup<T>(
  BuildContext context,
  Widget child, {
  double width = 560,
  bool dismissible = true,
}) {
  if (ResponsiveLayout.isMobile(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .94,
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: child,
        ),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: child,
        ),
      ),
    ),
  );
}
