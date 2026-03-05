import 'package:apptinhtoan5ma/controllers/calculator_controller.dart';
import 'package:apptinhtoan5ma/widget/numeric_keypad.dart';
import 'package:apptinhtoan5ma/view/simpleCalculator_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
