import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;

// ---------------------------------------------------------------------------
// Severity
// ---------------------------------------------------------------------------

enum LogLevel {
  trace(0, 'TRACE'),
  debug(1, 'DEBUG'),
  info(2, 'INFO'),
  warn(3, 'WARN'),
  error(4, 'ERROR'),
  fatal(5, 'FATAL');

  const LogLevel(this.rank, this.label);

  final int rank;
  final String label;

  bool operator >=(LogLevel other) => rank >= other.rank;
  bool operator <(LogLevel other) => rank < other.rank;
}

// ---------------------------------------------------------------------------
// Session ID
// ---------------------------------------------------------------------------

String generateSessionId() {
  final now = DateTime.now().toUtc();
  return 'session'
      '-${now.year.toString().padLeft(4, '0')}'
      '-${now.month.toString().padLeft(2, '0')}'
      '-${now.day.toString().padLeft(2, '0')}'
      '-${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
      '${now.second.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Fingerprint — FNV-1a 32-bit over 'evt|src|reason'
// ---------------------------------------------------------------------------

String fingerprint(String evt, String src, String reason) {
  final bytes = utf8.encode('$evt|$src|$reason');
  var hash = 0x811c9dc5;
  for (final b in bytes) {
    hash ^= b;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0').substring(0, 6);
}

// ---------------------------------------------------------------------------
// Correlation ID validation
// ---------------------------------------------------------------------------

bool isValidCid(String cid) =>
    RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+){2,}$').hasMatch(cid);

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

class LogConfig {
  const LogConfig({
    this.minConsoleLevel = LogLevel.debug,
    this.minFileLevel = LogLevel.trace,
    this.maxSessionLines = 50000,
    this.maxErrorLines = 10000,
    this.ringBufferSize = 500,
    this.enableSrc = kDebugMode,
    this.enableFocusSys,
  });

  /// Minimum level printed to console via debugPrint.
  final LogLevel minConsoleLevel;

  /// Minimum level written to session.log. Non-web only.
  final LogLevel minFileLevel;

  /// Soft-rotate session.log after this many lines.
  final int maxSessionLines;

  /// Soft-rotate errors.log after this many lines.
  final int maxErrorLines;

  /// In-memory ring buffer capacity. Works on all platforms including web.
  final int ringBufferSize;

  /// Capture caller file:line via StackTrace. Defaults to kDebugMode.
  final bool enableSrc;

  /// When set, events from this sys are also written to focus.log. Dev only.
  final String? enableFocusSys;
}
