import 'package:permission_handler/permission_handler.dart';
import '../constants/game_constants.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting microphone permission: $e');
      return false;
    }
  }

  Future<bool> isCameraPermissionGranted() async {
    try {
      final status = await Permission.camera.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking camera permission: $e');
      return false;
    }
  }

  Future<bool> isMicrophonePermissionGranted() async {
    try {
      final status = await Permission.microphone.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking microphone permission: $e');
      return false;
    }
  }

  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    results['camera'] = await requestCameraPermission();
    results['microphone'] = await requestMicrophonePermission();

    return results;
  }

  Future<bool> areAllPermissionsGranted() async {
    final cameraGranted = await isCameraPermissionGranted();
    final microphoneGranted = await isMicrophonePermissionGranted();

    return cameraGranted && microphoneGranted;
  }

  String getPermissionStatusMessage(Map<String, bool> permissions) {
    if (!permissions['camera']! && !permissions['microphone']!) {
      return 'Camera and microphone permissions are required';
    } else if (!permissions['camera']!) {
      return GameConstants.cameraPermissionDenied;
    } else if (!permissions['microphone']!) {
      return GameConstants.microphonePermissionDenied;
    }
    return 'All permissions granted';
  }

  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}
