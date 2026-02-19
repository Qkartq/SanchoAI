import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemInfo {
  final double cpuUsage;
  final double ramUsage;
  final int totalRam;
  final int usedRam;
  final int modelMemory;

  const SystemInfo({
    this.cpuUsage = 0,
    this.ramUsage = 0,
    this.totalRam = 0,
    this.usedRam = 0,
    this.modelMemory = 0,
  });
}

final systemInfoProvider = StateNotifierProvider<SystemInfoNotifier, SystemInfo>((ref) {
  return SystemInfoNotifier();
});

class SystemInfoNotifier extends StateNotifier<SystemInfo> {
  Timer? _timer;
  int _prevTotal = 0;
  int _prevIdle = 0;

  SystemInfoNotifier() : super(const SystemInfo()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    _updateInfo();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateInfo();
    });
  }

  void _updateInfo() {
    try {
      final memInfo = _readMemInfo();
      final totalRam = memInfo['total'] ?? 0;
      final freeRam = memInfo['free'] ?? 0;
      final usedRam = totalRam - freeRam;
      final ramUsage = totalRam > 0 ? (usedRam / totalRam) * 100 : 0.0;
      
      final cpuInfo = _readCpuInfo();
      
      state = SystemInfo(
        cpuUsage: cpuInfo,
        ramUsage: ramUsage,
        totalRam: totalRam,
        usedRam: usedRam,
        modelMemory: state.modelMemory,
      );
    } catch (e) {
      debugPrint('Error getting system info: $e');
    }
  }

  Map<String, int> _readMemInfo() {
    try {
      final file = File('/proc/meminfo');
      if (!file.existsSync()) {
        return {'total': 0, 'free': 0};
      }
      final content = file.readAsStringSync();
      final lines = content.split('\n');
      
      int total = 0;
      int free = 0;
      
      for (final line in lines) {
        if (line.startsWith('MemTotal:')) {
          final match = RegExp(r'(\d+)').firstMatch(line);
          if (match != null) {
            total = int.parse(match.group(1)!) * 1024;
          }
        } else if (line.startsWith('MemAvailable:')) {
          final match = RegExp(r'(\d+)').firstMatch(line);
          if (match != null) {
            free = int.parse(match.group(1)!) * 1024;
          }
        }
      }
      
      return {'total': total, 'free': free};
    } catch (e) {
      return {'total': 0, 'free': 0};
    }
  }

  double _readCpuInfo() {
    try {
      final file = File('/proc/stat');
      if (!file.existsSync()) {
        return 0;
      }
      final content = file.readAsStringSync();
      final lines = content.split('\n');
      
      for (final line in lines) {
        if (line.startsWith('cpu ')) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length < 5) continue;
          
          final user = int.tryParse(parts[1]) ?? 0;
          final nice = int.tryParse(parts[2]) ?? 0;
          final system = int.tryParse(parts[3]) ?? 0;
          final idle = int.tryParse(parts[4]) ?? 0;
          
          final total = user + nice + system + idle;
          final diffTotal = total - _prevTotal;
          final diffIdle = idle - _prevIdle;
          
          _prevTotal = total;
          _prevIdle = idle;
          
          if (diffTotal > 0) {
            return ((diffTotal - diffIdle) / diffTotal * 100).clamp(0, 100);
          }
          return 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void updateModelMemory(int bytes) {
    state = SystemInfo(
      cpuUsage: state.cpuUsage,
      ramUsage: state.ramUsage,
      totalRam: state.totalRam,
      usedRam: state.usedRam,
      modelMemory: bytes,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
