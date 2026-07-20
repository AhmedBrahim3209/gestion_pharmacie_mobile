import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getNotifications();
      _notifications = data.map((e) => AppNotification.fromJson(e)).toList();
      _unreadCount = _notifications.where((n) => !n.estLue).length;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.markAsRead(id);
      await loadNotifications();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllRead();
      await loadNotifications();
    } catch (e) {
      _error = e.toString();
    }
  }
}
