import 'package:apptinhtoan5ma/models/history_session.dart';
import 'package:apptinhtoan5ma/storage/history_storage.dart';
import 'package:apptinhtoan5ma/view/calculator_home_screen.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:apptinhtoan5ma/widget/history_dialog.dart';
import 'package:apptinhtoan5ma/widget/session_detail_dialog.dart';
import 'package:flutter/material.dart';

class CalculatorController extends GetxController {
  final input = ''.obs;

  // dữ liệu phiên hiện tại
  final numbers = <double>[].obs;
  final rawSum = 0.0.obs;

  // hệ số
  final multiplier = 0.0.obs;

  // ✅ 2 danh sách khác nhau
  final historySessions = <HistorySession>[].obs; // lưu tất cả
  final displaySessions = <HistorySession>[].obs; // dùng hiển thị + tổng tất cả

  // tổng tất cả = tổng của displaySessions
  final totalAllSessions = 0.0.obs;

  final showKeypad = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final h = await HistoryStorage.loadHistory();
    final d = await HistoryStorage.loadDisplay();

    historySessions.assignAll(h);
    displaySessions.assignAll(d);

    totalAllSessions.value = d.fold(0.0, (s, e) => s + e.finalTotal);
  }

  Future<void> _persistHistory() async =>
      HistoryStorage.saveHistory(historySessions);
  Future<void> _persistDisplay() async =>
      HistoryStorage.saveDisplay(displaySessions);

  void toggleKeypad() => showKeypad.value = !showKeypad.value;

  /* ------------ Nhập số (keypad) ------------ */

  void addDigit(String d) {
    if (d == '0' && input.value.isEmpty) return;
    input.value += d;
  }

  void addDot() {
    if (input.value.contains('.')) return;
    if (input.value.isEmpty) {
      input.value = '0.';
      return;
    }
    input.value += '.';
  }

  void backspace() {
    final t = input.value;
    if (t.isEmpty) return;
    input.value = t.substring(0, t.length - 1);
  }

  void clearInput() => input.value = '';

  void addNumber() {
    final txt = input.value.trim();
    final n = double.tryParse(txt);
    if (n == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập một số hợp lệ',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    numbers.add(n);
    rawSum.value += n;
    input.value = '';
  }

  /* ------------ Hệ số ------------ */

  void incMultiplier() {
    final next = _round1(multiplier.value + 0.1);
    multiplier.value = math.max(0.0, next);
  }

  void decMultiplier() {
    final next = _round1(multiplier.value - 0.1);
    multiplier.value = math.max(0.0, next);
  }

  double _round1(double v) => (v * 10).roundToDouble() / 10.0;

  Future<void> editMultiplierDialog() async {
    final tc = TextEditingController(text: prettyMultiplier(multiplier.value));

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Nhập hệ số'),
        content: TextField(
          controller: tc,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'VD: 0.0, 1.2 ...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final v = double.tryParse(tc.text.trim());
      if (v == null) {
        Get.snackbar(
          'Lỗi',
          'Hệ số không hợp lệ',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      multiplier.value = math.max(0.0, _round1(v));
    }
  }

  /* ------------ Kết mã / Reset ------------ */

  Future<void> finalizeSession() async {
    if (numbers.isEmpty) {
      Get.snackbar(
        'Thông báo',
        'Chưa có số nào để kết mã',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // sessionNo chạy theo lịch sử (để không trùng)
    final nextNo = historySessions.isEmpty
        ? 1
        : (historySessions.last.sessionNo + 1);

    final m = multiplier.value;
    final finalTotal = rawSum.value * m;

    final session = HistorySession(
      sessionNo: nextNo,
      numbers: List<double>.from(numbers),
      rawSum: rawSum.value,
      multiplier: m,
      finalTotal: finalTotal,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    // ✅ lưu vào cả 2 danh sách
    historySessions.add(session);
    displaySessions.add(session);

    totalAllSessions.value += finalTotal;

    await _persistHistory();
    await _persistDisplay();

    // reset phiên hiện tại
    numbers.clear();
    rawSum.value = 0.0;
    input.value = '';

    // Get.snackbar(
    //   'Đã kết mã',
    //   'Tổng phiên $nextNo: ${formatMoneyVN(session.rawSum)} × ${prettyMultiplier(m)} = ${formatMoneyVN(finalTotal)}',
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  }

  /// ✅ Reset: xoá danh sách HIỂN THỊ + tổng tất cả + phiên hiện tại
  /// ✅ KHÔNG XOÁ lịch sử
  Future<void> reset() async {
    Get.dialog(
      AlertDialog(
        title: Text("Thông báo"),
        content: Text("Bạn có chắc muốn xoá hay không ?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Huỷ")),
          TextButton(
            onPressed: () async {
              input.value = '';
              numbers.clear();
              rawSum.value = 0.0;
              multiplier.value = 0.0;

              // reset phần hiển thị + tổng
              displaySessions.clear();
              totalAllSessions.value = 0.0;

              await _persistDisplay();
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }
              Get.snackbar(
                "OK",
                "Đã reset xong",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text("Chấp nhận"),
          ),
        ],
      ),
    );
  }

  /// ✅ Xoá 1 phiên trong lịch sử (và xoá luôn khỏi display nếu đang có)
  Future<void> deleteHistoryAt(int index) async {
    if (index < 0 || index >= historySessions.length) return;
    final removed = historySessions.removeAt(index);

    // nếu phiên này đang nằm trong displaySessions thì xoá luôn + trừ tổng
    final di = displaySessions.indexWhere(
      (e) => e.createdAtMs == removed.createdAtMs,
    );
    if (di != -1) {
      final removedDisplay = displaySessions.removeAt(di);
      totalAllSessions.value -= removedDisplay.finalTotal;
      await _persistDisplay();
    }

    await _persistHistory();
  }

  void openHistoryDialog() => Get.dialog(const HistoryDialog());
  void openSessionDetailDialog(HistorySession session) =>
      Get.dialog(SessionDetailDialog(session: session));
}
