import 'dart:math';
import '../config/drive_config.dart';

class DirectoryCodeGenerator {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _random = Random.secure();

  static String generate() => List.generate(
    DriveConfig.codeLength,
    (_) => _alphabet[_random.nextInt(_alphabet.length)],
  ).join();

  static String normalize(String code) => code.trim().toUpperCase();

  static bool isValid(String code) =>
      RegExp(r'^[A-Z0-9]{6}$').hasMatch(normalize(code));
}
