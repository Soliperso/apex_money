import 'package:flutter/material.dart';

/// Service to manage dashboard state and synchronization across the app
class DashboardSyncService {
  static final DashboardSyncService _instance =
      DashboardSyncService._internal();
  factory DashboardSyncService() => _instance;
  DashboardSyncService._internal();

  /// Callback function that will be set by the dashboard to refresh its data
  VoidCallback? _refreshCallback;

  /// Set the refresh callback from the dashboard
  void setRefreshCallback(VoidCallback callback) {
    _refreshCallback = callback;
  }

  /// Clear the refresh callback when dashboard is disposed
  void clearRefreshCallback() {
    _refreshCallback = null;
  }

  /// Call this method whenever transactions are added, updated, or deleted
  /// to refresh the dashboard summary
  void refreshDashboard() {
    _refreshCallback?.call();
  }
}
