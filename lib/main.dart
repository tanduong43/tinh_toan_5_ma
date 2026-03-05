// main.dart
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

/* =========================================================
  APP ROOT
========================================================= */
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CalculatorHomeScreen(),
    );
  }
}

/* =========================
   MODELS + STORAGE
========================= */

class HistorySession {
  final int sessionNo; // Phiên N
  final List<double> numbers; // các số đã nhập trong phiên
  final double rawSum; // tổng trong phiên
  final double multiplier; // hệ số
  final double finalTotal; // rawSum * multiplier
  final int createdAtMs; // thời gian tạo (dùng làm ID ổn định)

  const HistorySession({
    required this.sessionNo,
    required this.numbers,
    required this.rawSum,
    required this.multiplier,
    required this.finalTotal,
    required this.createdAtMs,
  });

  Map<String, dynamic> toMap() => {
    'sessionNo': sessionNo,
    'numbers': numbers,
    'rawSum': rawSum,
    'multiplier': multiplier,
    'finalTotal': finalTotal,
    'createdAtMs': createdAtMs,
  };

  factory HistorySession.fromMap(Map<String, dynamic> map) {
    final raw = (map['numbers'] as List?) ?? const [];
    final nums = raw.map((e) => (e as num).toDouble()).toList();

    final rawSum = (map['rawSum'] as num?)?.toDouble() ?? _sumList(nums);
    final multiplier = (map['multiplier'] as num?)?.toDouble() ?? 0.0;

    return HistorySession(
      sessionNo: (map['sessionNo'] as num?)?.toInt() ?? 1,
      numbers: nums,
      rawSum: rawSum,
      multiplier: multiplier,
      finalTotal:
          (map['finalTotal'] as num?)?.toDouble() ?? (rawSum * multiplier),
      createdAtMs:
          (map['createdAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  static double _sumList(List<double> list) =>
      list.isEmpty ? 0.0 : list.reduce((a, b) => a + b);
}

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

/* =========================
   HELPERS
========================= */

String formatMoneyVN(num value) {
  final isNegative = value < 0;
  final absInt = value.abs().round();
  final s = absInt.toString();

  final buffer = StringBuffer();
  for (int i = s.length - 1, count = 0; i >= 0; i--, count++) {
    if (count % 3 == 0 && count != 0) buffer.write('.');
    buffer.write(s[i]);
  }
  final formatted = buffer.toString().split('').reversed.join();
  return isNegative ? '-$formatted' : formatted;
}

List<List<double>> chunkBy5(List<double> list) {
  final groups = <List<double>>[];
  for (int i = 0; i < list.length; i += 5) {
    final end = (i + 5 > list.length) ? list.length : i + 5;
    groups.add(list.sublist(i, end));
  }
  return groups;
}

String prettyMultiplier(double v) => v.toStringAsFixed(1);

/* =========================
   CONTROLLERS
========================= */

class SimpleCalculatorController extends GetxController {
  final display = '0'.obs;
  final calculation = ''.obs;

  double? _firstValue;
  String? _operation;
  bool _shouldResetDisplay = false;

  void clearAll() {
    display.value = '0';
    calculation.value = '';
    _firstValue = null;
    _operation = null;
    _shouldResetDisplay = false;
  }

  bool _isOp(String v) => v == '+' || v == '-' || v == '*' || v == '/';

  void press(String value) {
    if (value == 'C') return clearAll();
    if (value == '←') return _backspace();
    if (_isOp(value)) return _setOp(value);
    if (value == '=') return _equal();
    _append(value);
  }

  void _backspace() {
    final text = display.value;
    if (text.length > 1) {
      display.value = text.substring(0, text.length - 1);
    } else {
      display.value = '0';
    }
  }

  void _setOp(String op) {
    _firstValue = double.tryParse(display.value);
    _operation = op;
    calculation.value = '${display.value} $op';
    _shouldResetDisplay = true;
  }

  void _append(String value) {
    if (value == '.' && display.value.contains('.')) return;

    if (_shouldResetDisplay) {
      display.value = (value == '.') ? '0.' : value;
      _shouldResetDisplay = false;
      return;
    }

    final current = display.value;

    if (current == '0' && value != '.') {
      display.value = value;
      return;
    }

    display.value = current + value;
  }

  void _equal() {
    if (_firstValue == null || _operation == null) return;

    final secondValue = double.tryParse(display.value) ?? 0;
    double result = 0;

    switch (_operation) {
      case '+':
        result = _firstValue! + secondValue;
        break;
      case '-':
        result = _firstValue! - secondValue;
        break;
      case '*':
        result = _firstValue! * secondValue;
        break;
      case '/':
        result = secondValue != 0 ? _firstValue! / secondValue : 0;
        break;
    }

    final pretty = _prettyNumber(result);
    calculation.value = '${calculation.value} ${display.value} = $pretty';
    display.value = pretty;

    _firstValue = null;
    _operation = null;
    _shouldResetDisplay = true;
  }

  String _prettyNumber(double v) {
    final fixed = v.toStringAsFixed(2);
    return fixed.replaceAll(RegExp(r'\.?0+$'), '');
  }
}

/* ---------------------------------------------------------
  CalculatorController
  - historySessions: lịch sử (KHÔNG XOÁ khi reset)
  - displaySessions: chỉ để HIỂN THỊ + tổng tất cả (có thể xoá khi reset)
--------------------------------------------------------- */
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

    Get.snackbar(
      'Đã kết mã',
      'Tổng phiên $nextNo: ${formatMoneyVN(session.rawSum)} × ${prettyMultiplier(m)} = ${formatMoneyVN(finalTotal)}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// ✅ Reset: xoá danh sách HIỂN THỊ + tổng tất cả + phiên hiện tại
  /// ✅ KHÔNG XOÁ lịch sử
  Future<void> reset() async {
    // reset phiên hiện tại
    input.value = '';
    numbers.clear();
    rawSum.value = 0.0;
    multiplier.value = 0.0;

    // reset phần hiển thị + tổng
    displaySessions.clear();
    totalAllSessions.value = 0.0;

    await _persistDisplay();

    Get.snackbar(
      'Reset',
      'Đã reset tổng tất cả về 0 (lịch sử vẫn giữ nguyên)',
      snackPosition: SnackPosition.BOTTOM,
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

/* =========================
   UI - HOME
========================= */

class CalculatorHomeScreen extends StatelessWidget {
  const CalculatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CalculatorController());

    return Scaffold(
      appBar: AppBar(title: const Text('Ứng dụng Tính Toán')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final groups = chunkBy5(c.numbers);

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Danh sách phiên HIỂN THỊ ở màn hình tính toán
                      Obx(() {
                        if (c.displaySessions.isEmpty) {
                          return const Text(
                            'Chưa có phiên nào',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: c.displaySessions.map((s) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Tổng phiên ${s.sessionNo}: '
                                      '${formatMoneyVN(s.rawSum)} × ${prettyMultiplier(s.multiplier)} = ${formatMoneyVN(s.finalTotal)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Xem số liệu phiên này',
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () =>
                                        c.openSessionDetailDialog(s),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }),

                      const SizedBox(height: 14),

                      // Phiên hiện tại
                      if (c.numbers.isNotEmpty) ...[
                        const Text(
                          'Phiên hiện tại',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          children: groups.map((group) {
                            final sum = group.isEmpty
                                ? 0.0
                                : group.reduce((a, b) => a + b);

                            return Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  ...group.map(
                                    (num) => Text(formatMoneyVN(num)),
                                  ),
                                  const Divider(),
                                  Text('Tổng: ${formatMoneyVN(sum)}'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Hệ số
                      Row(
                        children: [
                          const Text(
                            'Hệ số:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: c.decMultiplier,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Obx(() {
                            return InkWell(
                              onTap: c.editMultiplierDialog,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  prettyMultiplier(c.multiplier.value),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                          IconButton(
                            onPressed: c.incMultiplier,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Tổng
                      Obx(() {
                        final currentRaw = c.rawSum.value;
                        final currentFinal =
                            c.rawSum.value * c.multiplier.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng phiên hiện tại: ${formatMoneyVN(currentRaw)} × ${prettyMultiplier(c.multiplier.value)} = ${formatMoneyVN(currentFinal)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tổng tất cả các phiên: ${formatMoneyVN(c.totalAllSessions.value)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 14),
                      _ActionRow(controller: c),
                    ],
                  ),
                );
              }),
            ),

            Obx(() {
              if (!c.showKeypad.value) return const SizedBox.shrink();
              final halfWidth = MediaQuery.of(context).size.width * 0.8;

              return Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(width: halfWidth, child: NumericKeypad()),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final CalculatorController controller;
  const _ActionRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton(
          onPressed: controller.finalizeSession,
          child: const Text('Kết mã'),
        ),
        ElevatedButton(
          onPressed: () async => await controller.reset(),
          child: const Text('Reset'),
        ),
        ElevatedButton(
          onPressed: controller.openHistoryDialog,
          child: const Text('Lịch sử'),
        ),
        ElevatedButton(
          onPressed: () => Get.to(() => const SimpleCalculatorScreen()),
          child: const Text('Máy tính'),
        ),
        Obx(() {
          final show = controller.showKeypad.value;
          return ElevatedButton.icon(
            onPressed: controller.toggleKeypad,
            icon: Icon(show ? Icons.keyboard_hide : Icons.keyboard),
            label: Text(show ? 'Ẩn' : 'Hiện'),
          );
        }),
      ],
    );
  }
}

/* =========================
   UI - NUMERIC KEYPAD (HOME)
========================= */

class NumericKeypad extends StatelessWidget {
  NumericKeypad({super.key});
  final c = Get.find<CalculatorController>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cellW = (constraints.maxWidth - 3 * 2) / 4;
        final btnH = cellW * 0.75;

        return Column(
          children: [
            Obx(() {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  c.input.value.isEmpty ? 'Nhập số...' : c.input.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.input.value.isEmpty ? Colors.grey : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
            GridView.count(
              crossAxisCount: 4,
              childAspectRatio: cellW / btnH,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ...[
                  '1',
                  '2',
                  '3',
                ].map((t) => _KeyBtn(text: t, onTap: () => c.addDigit(t))),
                _KeyBtn(
                  icon: Icons.backspace,
                  bg: Colors.orange,
                  onTap: c.backspace,
                ),
                ...[
                  '4',
                  '5',
                  '6',
                ].map((t) => _KeyBtn(text: t, onTap: () => c.addDigit(t))),
                _KeyBtn(icon: Icons.clear, bg: Colors.red, onTap: c.clearInput),
                ...[
                  '7',
                  '8',
                  '9',
                ].map((t) => _KeyBtn(text: t, onTap: () => c.addDigit(t))),
                _KeyBtn(
                  icon: Icons.check,
                  bg: Colors.green,
                  onTap: c.addNumber,
                ),
                _KeyBtn(text: '0', onTap: () => c.addDigit('0')),
                _KeyBtn(text: '.', onTap: c.addDot),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final Color? bg;
  final VoidCallback onTap;

  const _KeyBtn({this.text, this.icon, this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIcon = icon != null;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(2),
        backgroundColor: bg,
      ),
      child: isIcon
          ? Icon(icon, size: 14, color: Colors.white)
          : Text(
              text ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
    );
  }
}

/* =========================
   UI - SESSION DETAIL
========================= */

class SessionDetailDialog extends StatelessWidget {
  final HistorySession session;
  const SessionDetailDialog({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final numbers = session.numbers;
    final groups = chunkBy5(numbers);

    return AlertDialog(
      title: Text('Chi tiết Phiên ${session.sessionNo}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Số lượng số: ${numbers.length}'),
              const SizedBox(height: 8),
              Text(
                'Tổng: ${formatMoneyVN(session.rawSum)} × ${prettyMultiplier(session.multiplier)} = ${formatMoneyVN(session.finalTotal)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              const Text(
                'Dữ liệu của phiên:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...groups.map((group) {
                final groupSum = group.isEmpty
                    ? 0.0
                    : group.reduce((a, b) => a + b);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${group.map(formatMoneyVN).join(', ')} | Tổng: ${formatMoneyVN(groupSum)}',
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
      ],
    );
  }
}

/* =========================
   UI - HISTORY DIALOG
   - dùng historySessions (không bị reset xoá)
========================= */

class HistoryDialog extends StatelessWidget {
  const HistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CalculatorController>();

    return AlertDialog(
      title: const Text('Lịch sử (tất cả phiên đã kết mã)'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Obx(() {
          if (c.historySessions.isEmpty) {
            return const Center(child: Text('Chưa có lịch sử'));
          }

          return ListView.builder(
            itemCount: c.historySessions.length,
            itemBuilder: (context, index) {
              final session = c.historySessions[index];
              final numbers = session.numbers;
              final groups = chunkBy5(numbers);

              return ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Phiên ${session.sessionNo}: ${numbers.length} số',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Xoá phiên này',
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final ok = await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text('Xoá lịch sử'),
                            content: Text(
                              'Bạn muốn xoá Phiên ${session.sessionNo} chứ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Huỷ'),
                              ),
                              ElevatedButton(
                                onPressed: () => Get.back(result: true),
                                child: const Text('Xoá'),
                              ),
                            ],
                          ),
                        );

                        if (ok == true) {
                          await c.deleteHistoryAt(index);
                          Get.snackbar(
                            'Đã xoá',
                            'Đã xoá Phiên ${session.sessionNo}',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    ),
                  ],
                ),
                subtitle: Text(
                  'Tổng: ${formatMoneyVN(session.rawSum)} × ${prettyMultiplier(session.multiplier)} = ${formatMoneyVN(session.finalTotal)}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dữ liệu của phiên:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        ...groups.map((group) {
                          final groupSum = group.isEmpty
                              ? 0.0
                              : group.reduce((a, b) => a + b);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '${group.map(formatMoneyVN).join(', ')} | Tổng: ${formatMoneyVN(groupSum)}',
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Text('Tổng phiên: ${formatMoneyVN(session.rawSum)}'),
                        Text('Hệ số: ${prettyMultiplier(session.multiplier)}'),
                        Text(
                          'Tổng tiền của phiên: ${formatMoneyVN(session.finalTotal)}',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
      ],
    );
  }
}

/* =========================
   UI - SIMPLE CALCULATOR
========================= */

class SimpleCalculatorScreen extends StatelessWidget {
  const SimpleCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SimpleCalculatorController());

    return Scaffold(
      appBar: AppBar(title: const Text('Máy tính')),
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              return Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerRight,
                child: Text(
                  c.calculation.value,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            Obx(() {
              return Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerRight,
                child: Text(
                  c.display.value,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _simpleButtons(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _simpleButtons(SimpleCalculatorController c) {
    final buttons = [
      'C',
      '/',
      '*',
      '←',
      '7',
      '8',
      '9',
      '-',
      '4',
      '5',
      '6',
      '+',
      '1',
      '2',
      '3',
      '=',
      '0',
      '.',
      '00',
      '',
    ];

    return buttons.map((btn) {
      if (btn.isEmpty) return const SizedBox.shrink();

      Color buttonColor = Colors.grey[300]!;
      if (btn == '=' || btn == '+' || btn == '-' || btn == '*' || btn == '/') {
        buttonColor = Colors.orange;
      } else if (btn == 'C' || btn == '←') {
        buttonColor = Colors.red;
      }

      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () => c.press(btn),
        child: Text(
          btn,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }).toList();
  }
}
