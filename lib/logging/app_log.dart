import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'log_config.dart';
import 'log_observer.dart';

// ---------------------------------------------------------------------------
// Top-level accessor — use this at callsites
// ---------------------------------------------------------------------------

AppLog get appLog => AppLog.instance;

// ---------------------------------------------------------------------------
// Ring buffer entry
// ---------------------------------------------------------------------------

class LogEntry {
  const LogEntry({
    required this.ts,
    required this.level,
    required this.sys,
    required this.evt,
    required this.json,
  });

  final DateTime ts;
  final LogLevel level;
  final String sys;
  final String evt;
  final String json;
}

// ---------------------------------------------------------------------------
// File I/O — file-private
// ---------------------------------------------------------------------------

class _LogWriters {
  _LogWriters(this._config);

  final LogConfig _config;

  String? _logDir;
  IOSink? _sessionSink;
  IOSink? _errorsSink;
  IOSink? _focusSink;

  int _sessionLines = 0;
  int _errorsLines = 0;

  Future<void> _chain = Future.value();

  int get sessionLineCount => _sessionLines;
  int get errorsLineCount => _errorsLines;
  String? get logDir => _logDir;

  Future<void> init(String logDir) async {
    if (kIsWeb) return;
    _logDir = logDir;
    await Directory(logDir).create(recursive: true);
    _sessionSink = _openAppend('$logDir/session.log');
    _errorsSink = _openAppend('$logDir/errors.log');
    if (_config.enableFocusSys != null) {
      _focusSink = File('$logDir/focus.log').openWrite();
    }
  }

  void writeLine(String line, LogLevel level, String sys) {
    if (kIsWeb) return;
    _chain = _chain.then((_) async {
      if (level >= _config.minFileLevel) {
        if (_sessionLines >= _config.maxSessionLines) {
          await _rotate('session.log', (s) => _sessionSink = s);
          _sessionLines = 0;
        }
        _sessionSink?.writeln(line);
        _sessionLines++;
      }
      if (level >= LogLevel.warn) {
        if (_errorsLines >= _config.maxErrorLines) {
          await _rotate('errors.log', (s) => _errorsSink = s);
          _errorsLines = 0;
        }
        _errorsSink?.writeln(line);
        _errorsLines++;
      }
      if (_focusSink != null && sys == _config.enableFocusSys) {
        _focusSink!.writeln(line);
      }
    }).catchError((Object e) {
      // ignore: avoid_print
      print('[AppLog] write error: $e');
    });
  }

  void writeSummary(String content) {
    if (kIsWeb) return;
    _chain = _chain.then((_) async {
      final path = '$_logDir/summary.log';
      await File(path).writeAsString(content);
    }).catchError((Object e) {
      // ignore: avoid_print
      print('[AppLog] summary write error: $e');
    });
  }

  Future<void> flush() async {
    if (kIsWeb) return;
    await _chain;
    await Future.wait([
      _sessionSink?.flush() ?? Future.value(),
      _errorsSink?.flush() ?? Future.value(),
      _focusSink?.flush() ?? Future.value(),
    ]);
  }

  Future<void> close() async {
    if (kIsWeb) return;
    await flush();
    await Future.wait([
      _sessionSink?.close() ?? Future.value(),
      _errorsSink?.close() ?? Future.value(),
      _focusSink?.close() ?? Future.value(),
    ]);
  }

  IOSink _openAppend(String path) =>
      File(path).openWrite(mode: FileMode.append);

  Future<void> _rotate(String name, void Function(IOSink) assign) async {
    final old = '$_logDir/$name';
    final bak =
        '$_logDir/${name.replaceAll('.log', '')}-${DateTime.now().millisecondsSinceEpoch}.log';
    await File(old).rename(bak);
    assign(_openAppend(old));
  }
}

// ---------------------------------------------------------------------------
// In-memory summary accounting — file-private
// ---------------------------------------------------------------------------

class _CidEntry {
  _CidEntry({
    required this.sys,
    required this.lastEvt,
    required this.count,
    required this.firstTs,
    required this.lastTs,
  });

  final String sys;
  String lastEvt;
  int count;
  final String firstTs;
  String lastTs;
}

class _LogSummary {
  _LogSummary(this._writers, this._sessionId);

  final _LogWriters _writers;
  final String _sessionId;

  final Map<String, int> _systemErrorCounts = {};
  final Map<String, int> _systemEventCounts = {};
  final Map<String, int> _levelCounts = {};
  final Map<String, String> _fpFirstSeen = {};
  final Map<String, _CidEntry> _cidIndex = {};
  final List<String> _cidOrder = [];

  DateTime? _startTime;
  DateTime? _lastEventTime;

  void record({
    required LogLevel level,
    required String sys,
    required String evt,
    required String fp,
    required String? cid,
    required DateTime ts,
  }) {
    _startTime ??= ts;
    _lastEventTime = ts;

    _systemEventCounts[sys] = (_systemEventCounts[sys] ?? 0) + 1;
    _levelCounts[level.label] = (_levelCounts[level.label] ?? 0) + 1;

    if (level >= LogLevel.warn) {
      _systemErrorCounts[sys] = (_systemErrorCounts[sys] ?? 0) + 1;
    }

    _fpFirstSeen.putIfAbsent(fp, () => ts.toIso8601String());

    if (cid != null && cid.isNotEmpty) {
      final entry = _cidIndex[cid];
      if (entry == null) {
        _cidIndex[cid] = _CidEntry(
          sys: sys,
          lastEvt: evt,
          count: 1,
          firstTs: ts.toIso8601String(),
          lastTs: ts.toIso8601String(),
        );
        _cidOrder.add(cid);
      } else {
        entry.lastEvt = evt;
        entry.count++;
        entry.lastTs = ts.toIso8601String();
      }
    }
  }

  void flush() => _writers.writeSummary(_build());

  String _build() {
    final buf = StringBuffer();
    final now = DateTime.now().toUtc().toIso8601String();

    buf.writeln('# AppLog Summary');
    buf.writeln('# Session : $_sessionId');
    buf.writeln('# Updated : $now');
    buf.writeln('# Claude  : read this first, then errors.log, then session.log');
    buf.writeln();

    buf.writeln('## Systems with Errors (WARN+)');
    if (_systemErrorCounts.isEmpty) {
      buf.writeln('  (none)');
    } else {
      final sorted = _systemErrorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted) {
        buf.writeln('  ${e.key.padRight(20)} ${e.value}');
      }
    }
    buf.writeln();

    buf.writeln('## File Line Counts');
    buf.writeln('  session.log : ${_writers.sessionLineCount}');
    buf.writeln('  errors.log  : ${_writers.errorsLineCount}');
    buf.writeln();

    buf.writeln('## Level Breakdown');
    for (final lvl in LogLevel.values) {
      final n = _levelCounts[lvl.label] ?? 0;
      if (n > 0) buf.writeln('  ${lvl.label.padRight(6)} $n');
    }
    buf.writeln();

    buf.writeln('## All Systems');
    final allSorted = _systemEventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in allSorted) {
      buf.writeln('  ${e.key.padRight(20)} ${e.value}');
    }
    buf.writeln();

    buf.writeln('## CID Index');
    if (_cidOrder.isEmpty) {
      buf.writeln('  (none)');
    } else {
      for (final cid in _cidOrder) {
        final e = _cidIndex[cid]!;
        buf.writeln(
          '  ${cid.padRight(30)} sys=${e.sys.padRight(12)} '
          'n=${e.count.toString().padLeft(3)}  last=${e.lastEvt}',
        );
        buf.writeln('    first=${e.firstTs}  last=${e.lastTs}');
      }
    }
    buf.writeln();

    buf.writeln('## Fingerprint Index (WARN+ dedup)');
    if (_fpFirstSeen.isEmpty) {
      buf.writeln('  (none)');
    } else {
      for (final e in _fpFirstSeen.entries) {
        buf.writeln('  ${e.key}  first_seen=${e.value}');
      }
    }
    buf.writeln();

    if (_startTime != null) {
      buf.writeln('## Session Timing');
      buf.writeln('  start    : ${_startTime!.toIso8601String()}');
      if (_lastEventTime != null) {
        buf.writeln('  last_evt : ${_lastEventTime!.toIso8601String()}');
      }
      buf.writeln();
    }

    if (_writers.logDir != null) {
      buf.writeln('## Log Files');
      buf.writeln('  ${_writers.logDir}');
    }

    return buf.toString();
  }
}

// ---------------------------------------------------------------------------
// AppLog — public singleton
// ---------------------------------------------------------------------------

class AppLog with WidgetsBindingObserver {
  AppLog._();

  static AppLog? _instance;
  static AppLog get instance => _instance ??= AppLog._();

  late LogConfig _config;
  late String _sessionId;
  late _LogWriters _writers;
  late _LogSummary _summary;
  late LogObserver _observer;

  bool _initialised = false;
  final Queue<LogEntry> _ring = Queue<LogEntry>();

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  static Future<void> init({LogConfig config = const LogConfig()}) async {
    final self = AppLog.instance;
    if (self._initialised) return;

    self._config = config;
    self._sessionId = generateSessionId();

    String logDir;
    if (kIsWeb) {
      logDir = '';
    } else {
      final dir = await getApplicationSupportDirectory();
      logDir = '${dir.path}/logs';
    }

    self._writers = _LogWriters(config);
    await self._writers.init(logDir);
    self._summary = _LogSummary(self._writers, self._sessionId);

    self._observer = LogObserver(
      onRouteChanged: (from, to) => self._log(
        LogLevel.info,
        'route',
        'route.changed',
        cid: null,
        ctx: {'from': from, 'to': to},
      ),
    );

    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(self);

    self._initialised = true;
    self._log(LogLevel.info, 'app', 'app.start',
        cid: null, ctx: {'session': self._sessionId});
  }

  LogObserver get observer => _observer;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  void trace(String sys, String evt,
          {String? cid, Map<String, dynamic>? ctx}) =>
      _log(LogLevel.trace, sys, evt, cid: cid, ctx: ctx);

  void debug(String sys, String evt,
          {String? cid, Map<String, dynamic>? ctx}) =>
      _log(LogLevel.debug, sys, evt, cid: cid, ctx: ctx);

  void info(String sys, String evt,
          {String? cid, Map<String, dynamic>? ctx}) =>
      _log(LogLevel.info, sys, evt, cid: cid, ctx: ctx);

  void warn(String sys, String evt, {
    required String cid,
    required Map<String, dynamic> ctx,
  }) =>
      _log(LogLevel.warn, sys, evt, cid: cid, ctx: ctx);

  void error(String sys, String evt, {
    required String cid,
    required Map<String, dynamic> ctx,
  }) =>
      _log(LogLevel.error, sys, evt, cid: cid, ctx: ctx);

  void fatal(String sys, String evt, {
    required String cid,
    required Map<String, dynamic> ctx,
  }) =>
      _log(LogLevel.fatal, sys, evt, cid: cid, ctx: ctx);

  // ---------------------------------------------------------------------------
  // Internal dispatch
  // ---------------------------------------------------------------------------

  void _log(
    LogLevel level,
    String sys,
    String evt, {
    required String? cid,
    required Map<String, dynamic>? ctx,
  }) {
    if (!_initialised) {
      debugPrint('[AppLog] warning: logged before init — $sys/$evt');
      return;
    }

    final ts = DateTime.now().toUtc();
    final src = _config.enableSrc ? _callerSrc() : '';
    final reason = ctx?['reason']?.toString() ?? '';
    final fp = fingerprint(evt, src, reason);

    assert(
      level < LogLevel.warn ||
          (cid != null && isValidCid(cid)),
      'AppLog: WARN+ requires a valid cid (sys-noun-counter). '
      'Got: "$cid"  event=$sys/$evt',
    );
    assert(
      level < LogLevel.warn ||
          (ctx != null && ctx.containsKey('reason')),
      'AppLog: WARN+ requires ctx["reason"] (stable code, not prose). '
      'event=$sys/$evt',
    );

    final entry = <String, dynamic>{
      'ts': ts.toIso8601String(),
      'lvl': level.label,
      'sys': sys,
      'evt': evt,
      if (cid != null && cid.isNotEmpty) 'cid': cid,
      'sid': _sessionId,
      if (src.isNotEmpty) 'src': src,
      'fp': fp,
      'route': _observer.currentRoute,
      if (ctx != null && ctx.isNotEmpty) 'ctx': ctx,
    };

    final line = jsonEncode(entry);

    _ring.addLast(LogEntry(ts: ts, level: level, sys: sys, evt: evt, json: line));
    while (_ring.length > _config.ringBufferSize) {
      _ring.removeFirst();
    }

    if (level >= _config.minConsoleLevel) {
      debugPrint(
        '[${level.label}] $sys/$evt'
        '${cid != null ? ' ($cid)' : ''}'
        '${ctx != null && ctx.isNotEmpty ? ' $ctx' : ''}',
      );
    }

    _writers.writeLine(line, level, sys);
    _summary.record(
      level: level,
      sys: sys,
      evt: evt,
      fp: fp,
      cid: cid,
      ts: ts,
    );

    if (level >= LogLevel.error) { _summary.flush(); }
  }

  // ---------------------------------------------------------------------------
  // Caller source
  // ---------------------------------------------------------------------------

  String _callerSrc() {
    try {
      for (final frame in StackTrace.current.toString().split('\n')) {
        if (frame.isEmpty) continue;
        if (frame.contains('app_log') ||
            frame.contains('log_config') ||
            frame.contains('log_observer')) {
          continue;
        }
        final m = RegExp(r'(\w+\.dart):(\d+)').firstMatch(frame);
        if (m != null) return '${m.group(1)}:${m.group(2)}';
      }
    } catch (_) {}
    return '';
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _log(LogLevel.info, 'app', 'app.background', cid: null, ctx: null);
        _summary.flush();
        _writers.flush();
      case AppLifecycleState.resumed:
        _log(LogLevel.info, 'app', 'app.foreground', cid: null, ctx: null);
      case AppLifecycleState.detached:
        _log(LogLevel.info, 'app', 'app.shutdown', cid: null, ctx: null);
        _summary.flush();
        _writers.flush();
      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  Future<void> flush() async {
    _summary.flush();
    await _writers.flush();
  }

  Future<void> close() async {
    _summary.flush();
    await _writers.close();
  }

  List<LogEntry> recentEntries({int count = 100, LogLevel? minLevel}) {
    var entries = _ring.toList();
    if (minLevel != null) {
      entries = entries.where((e) => e.level >= minLevel).toList();
    }
    return entries.reversed.take(count).toList();
  }

  static void resetForTesting() => _instance = null;
}
