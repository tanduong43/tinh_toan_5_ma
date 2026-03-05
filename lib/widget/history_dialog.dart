import 'package:apptinhtoan5ma/controllers/calculator_controller.dart';
import 'package:apptinhtoan5ma/view/calculator_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                          // Get.snackbar(
                          //   'Đã xoá',
                          //   'Đã xoá Phiên ${session.sessionNo}',
                          //   snackPosition: SnackPosition.BOTTOM,
                          // );
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
