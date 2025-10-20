import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

/// Service for handling app permissions
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    try {
      final status = await Permission.camera.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking camera permission: $e');
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> isMicrophonePermissionGranted() async {
    try {
      final status = await Permission.microphone.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking microphone permission: $e');
      return false;
    }
  }

  /// Request all required permissions for the game
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    
    results['camera'] = await requestCameraPermission();
    results['microphone'] = await requestMicrophonePermission();
    
    return results;
  }

  /// Check if all required permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    final cameraGranted = await isCameraPermissionGranted();
    final microphoneGranted = await isMicrophonePermissionGranted();
    
    return cameraGranted && microphoneGranted;
  }

  /// Get permission status message
  String getPermissionStatusMessage(Map<String, bool> permissions) {
    if (!permissions['camera']! && !permissions['microphone']!) {
      return 'Camera and microphone permissions are required';
    } else if (!permissions['camera']!) {
      return AppConstants.cameraPermissionDenied;
    } else if (!permissions['microphone']!) {
      return AppConstants.microphonePermissionDenied;
    }
    return 'All permissions granted';
  }

  /// Open app settings for manual permission granting
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}
