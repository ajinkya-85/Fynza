import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/models/backup_failure.dart';
import '../models/backup_dto.dart';

class BackupSerializer {
  static const String backupExtension = 'expbak';
  static const int currentFormatVersion = 1;

  static const List<int> gzipMagicBytes = [0x1F, 0x8B];

  /// Compresses [envelope] into gzipped UTF-8 JSON bytes.
  Uint8List encode(BackupEnvelopeDto envelope) {
    final jsonStr = jsonEncode(envelope.toJson());
    final utf8Bytes = utf8.encode(jsonStr);
    final compressed = gzip.encode(utf8Bytes);
    return Uint8List.fromList(compressed);
  }

  /// Decompresses and parses gzipped JSON bytes into a raw Map.
  /// Throws [InvalidFileFailure] on corrupted gzip or malformed JSON.
  Map<String, dynamic> decode(Uint8List bytes) {
    if (bytes.length < 2) {
      throw const InvalidFileFailure('The file is empty or too short.');
    }

    // Check gzip magic bytes
    if (bytes[0] != gzipMagicBytes[0] || bytes[1] != gzipMagicBytes[1]) {
      throw const InvalidFileFailure('The file is not a valid compressed backup.');
    }

    List<int> decompressed;
    try {
      decompressed = gzip.decode(bytes);
    } catch (_) {
      throw const InvalidFileFailure('The backup file is corrupted and cannot be decompressed.');
    }

    String jsonStr;
    try {
      jsonStr = utf8.decode(decompressed);
    } catch (_) {
      throw const InvalidFileFailure('The backup file contains invalid text encoding.');
    }

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        throw const InvalidFileFailure('The backup root structure is invalid.');
      }
      return decoded;
    } catch (e) {
      if (e is BackupFailure) rethrow;
      throw const InvalidFileFailure('The backup file contains invalid JSON data.');
    }
  }
}
