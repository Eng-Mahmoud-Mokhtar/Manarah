import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  // Future مشترك لضمان عدم طلب الأذونات أكتر من مرة
  static Future<bool>? _permissionFuture;

  // دالة رئيسية لطلب كل الأذونات
  static Future<bool> requestPermissions() {
    if (_permissionFuture != null) return _permissionFuture!;
    _permissionFuture = _request();
    return _permissionFuture!;
  }

  static Future<bool> _request() async {
    try {
      // طلب الأذونات الأساسية
      final statuses = await [
        Permission.locationWhenInUse,
        Permission.notification,
      ].request();

      bool allGranted = statuses.values.every((status) => status.isGranted);

      // التعامل مع رفض المستخدم نهائيًا
      if (!allGranted) {
        bool permanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);

        if (permanentlyDenied) {
          await openAppSettings(); // فتح إعدادات التطبيق
        }
      }

      // خيار إضافي: تجاهل تحسين البطارية إذا مدعوم
      if (await Permission.ignoreBatteryOptimizations.isRestricted == false &&
          await Permission.ignoreBatteryOptimizations.isGranted == false) {
        await Permission.ignoreBatteryOptimizations.request();
      }

      return allGranted;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    } finally {
      // مسح Future عشان يمكن الطلب مرة تانية لاحقًا
      _permissionFuture = null;
    }
  }

  // دالة مساعدة للتحقق إذا كل الأذونات موجودة بالفعل
  static Future<bool> checkPermissions() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final notificationStatus = await Permission.notification.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    return locationStatus.isGranted &&
        notificationStatus.isGranted &&
        batteryStatus.isGranted;
  }
}
