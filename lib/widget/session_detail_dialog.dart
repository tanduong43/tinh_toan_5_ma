import 'package:apptinhtoan5ma/models/history_session.dart';
import 'package:apptinhtoan5ma/view/calculator_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
