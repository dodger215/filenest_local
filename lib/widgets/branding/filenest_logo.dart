import 'package:flutter/material.dart';

class FileNestLogo extends StatelessWidget {
  final double size;
  const FileNestLogo({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'FileNest',
    image: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.folder_rounded, color: Colors.white, size: size * .65),
          Positioned(
            right: size * .15,
            bottom: size * .16,
            child: Icon(
              Icons.description_rounded,
              color: const Color(0xFFBFDBFE),
              size: size * .35,
            ),
          ),
        ],
      ),
    ),
  );
}
