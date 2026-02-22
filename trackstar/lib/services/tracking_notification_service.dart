
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
void trackingTaskEntryPoint() {
  FlutterForegroundTask.setTaskHandler(_TrackingTaskHandler());
}

class _TrackingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final title = data['title'] as String? ?? 'TrackStar';
    final text  = data['text']  as String? ?? '';
    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText:  text,
    );
  }
}

// Singleton
class TrackingNotificationService {
  static final TrackingNotificationService instance =
      TrackingNotificationService._();
  TrackingNotificationService._();

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'trackstar_active',
        channelName: 'TrackStar – Aktivna Sesija',
        channelDescription:
            'Prikazuje vaše trenutne statistike dok pratite aktivnost.',
        channelImportance: NotificationChannelImportance.LOW, // low importance as default
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // loop every 5 s
        autoRunOnBoot: false,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Starts the foreground service with an initial notification
  Future<void> start({required String activityLabel}) async {
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'TrackStar – $activityLabel u toku',
      notificationText: '0:00  •  0.00 km  •  0.0 km/h',
      callback: trackingTaskEntryPoint,
    );
  }

  void updateStats({
    required String activityLabel,
    required int    elapsed,
    required double distanceKm,
    required double speedKmh,
  }) {
    final h = elapsed ~/ 3600;
    final m = (elapsed % 3600) ~/ 60;
    final s = elapsed % 60;
    final timeStr = h > 0
        ? '${h}h ${m.toString().padLeft(2, '0')}m'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    FlutterForegroundTask.sendDataToTask({
      'title': 'TrackStar – $activityLabel u toku',
      'text':
          '$timeStr  •  ${distanceKm.toStringAsFixed(2)} km  •  ${speedKmh.toStringAsFixed(1)} km/h',
    });
  }

  // Stops the foreground service and dismisses the notification
  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  // Naive internet check
  // Returns false within ~2 s if offline
  static Future<bool> hasInternetConnection() async {
    try {
      print('[TrackingNotificationService] checking internet...');
      final result = await Future.any([
        _socketCheck(),
        Future.delayed(const Duration(seconds: 2), () => false),
      ]);
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _socketCheck() async {
    try {
      return true; // placeholder
    } catch (_) {
      return false;
    }
  }
}