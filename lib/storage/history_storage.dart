import 'package:apptinhtoan5ma/models/history_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryStorage {
  // ✅ Lịch sử: lưu tất cả phiên đã kết mã
  static const _keyHistory = 'calc_history_all_v3';

  // ✅ Hiển thị ở màn hình tính toán: ví dụ chỉ các phiên "từ lần reset gần nhất"
  static const _keyDisplay = 'calc_display_sessions_v3';

  static Future<List<HistorySession>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyHistory);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => HistorySession.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveHistory(List<HistorySession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(sessions.map((e) => e.toMap()).toList());
    await prefs.setString(_keyHistory, raw);
  }

  static Future<List<HistorySession>> loadDisplay() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDisplay);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => HistorySession.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveDisplay(List<HistorySession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(sessions.map((e) => e.toMap()).toList());
    await prefs.setString(_keyDisplay, raw);
  }
}
