import 'package:flutter/foundation.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/permission_service.dart';

/// Global application state provider
class AppStateProvider extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final PermissionService _permissionService = PermissionService();
  
  // App state
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, bool> _permissions = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, bool> get permissions => _permissions;
  CameraService get cameraService => _cameraService;
  PermissionService get permissionService => _permissionService;

  /// Initialize the application
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      // Check and request permissions
      await _checkPermissions();
      
      // Initialize camera service
      await _cameraService.initialize();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize app: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Check and request all required permissions
  Future<void> _checkPermissions() async {
    try {
      _permissions = await _permissionService.requestAllPermissions();
      
      if (!_permissions['camera']! || !_permissions['microphone']!) {
        throw Exception(_permissionService.getPermissionStatusMessage(_permissions));
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  /// Retry initialization
  Future<void> retryInitialization() async {
    _isInitialized = false;
    await initialize();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}
