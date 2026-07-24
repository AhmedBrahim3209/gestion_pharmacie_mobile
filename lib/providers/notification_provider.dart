import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String _statusFilter = 'toutes';
  String _typeFilter = 'toutes';
  String _searchQuery = '';

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get statusFilter => _statusFilter;
  String get typeFilter => _typeFilter;
  String get searchQuery => _searchQuery;

  void setStatusFilter(String v) {
    _statusFilter = v;
    _currentPage = 1;
    _notifications = [];
    _hasMore = true;
    loadNotifications();
  }

  void setTypeFilter(String v) {
    _typeFilter = v;
    _currentPage = 1;
    _notifications = [];
    _hasMore = true;
    loadNotifications();
  }

  void setSearchQuery(String v) {
    _searchQuery = v;
    _currentPage = 1;
    _notifications = [];
    _hasMore = true;
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getNotificationsPaginated(
        page: _currentPage,
        status: _statusFilter,
        type: _typeFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      final results = data['results'] as List? ?? [];
      _hasMore = data['next'] != null;
      _notifications = results.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
      if (_currentPage == 1) {
        final allData = await _api.getNotifications();
        _unreadCount = allData.where((n) => !n.estLue).length;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      _currentPage++;
      final data = await _api.getNotificationsPaginated(
        page: _currentPage,
        status: _statusFilter,
        type: _typeFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      final results = data['results'] as List? ?? [];
      _hasMore = data['next'] != null;
      _notifications.addAll(results.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      _error = e.toString();
    }
    _isLoadingMore = false;
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

  Future<void> deleteNotification(int id) async {
    try {
      await _api.deleteNotification(id);
      await loadNotifications();
    } catch (e) {
      _error = e.toString();
    }
  }
}
