import 'package:apptinhtoan5ma/controllers/calculator_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
