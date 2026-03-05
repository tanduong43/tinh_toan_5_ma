import 'package:apptinhtoan5ma/controllers/simple_calculator_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
