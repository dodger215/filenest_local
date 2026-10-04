import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class CodeShareService {
  static Future<void> share(
    BuildContext context,
    String code, {
    String? backendUrl,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Join my FileNest folder using code: $code.${backendUrl == null ? '' : '\nSet your backend URL to $backendUrl.'}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}
