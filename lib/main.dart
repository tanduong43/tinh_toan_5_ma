import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CalculatorApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  _CalculatorAppState createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  final TextEditingController _controller = TextEditingController();
  final List<double> _numbers = [];
  double _totalSum = 0.0;
  String _operation = '+';
  final TextEditingController _valueController = TextEditingController();
  String _lastOperation = '';
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _history = [];
  bool _isFinalized = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _formatVND(double value) {
    final intValue = value.toInt();
    final str = intValue.toString();
    final buffer = StringBuffer();
    for (int i = str.length - 1, count = 0; i >= 0; i--, count++) {
      if (count % 3 == 0 && count != 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${buffer.toString().split('').reversed.join()} VND';
  }

  void _addNumber() {
    final input = _controller.text.trim();
    final number = double.tryParse(input);
    if (number != null) {
      setState(() {
        if (_isFinalized) {
          final remaining = 5 - (_numbers.length % 5);
          if (remaining != 5) {
            for (int i = 0; i < remaining; i++) {
              _numbers.add(0.0);
            }
          }
          _isFinalized = false;
        }
        _numbers.add(number);
        _totalSum += number;
      });
      _controller.clear();
      _focusNode.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập một số hợp lệ')),
      );
    }
  }

  void _finalize() {
    setState(() {
      _isFinalized = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã tổng kết. Tổng tất cả: ${_formatVND(_totalSum).replaceAll(' VND', '')}',
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _history.add({
        'numbers': List<double>.from(_numbers),
        'finalTotal': _totalSum,
      });
      _numbers.clear();
      _totalSum = 0.0;
      _lastOperation = '';
      _isFinalized = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã reset và lưu vào lịch sử')),
    );
  }

  void _applyOperation() {
    final value = double.tryParse(_valueController.text.trim());
    if (value != null) {
      final oldTotal = _totalSum;
      setState(() {
        switch (_operation) {
          case '+':
            _totalSum += value;
            break;
          case '-':
            _totalSum -= value;
            break;
          case '*':
            _totalSum *= value;
            break;
          case '/':
            if (value != 0) _totalSum /= value;
            break;
        }
        _lastOperation =
            '${_formatVND(oldTotal).replaceAll(' VND', '')} $_operation ${_formatVND(value).replaceAll(' VND', '')} = ${_formatVND(_totalSum)}';
      });
      _valueController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập một giá trị hợp lệ')),
      );
    }
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lịch sử'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final session = _history[index];
              final numbers = List<double>.from(session['numbers']);
              final finalTotal = session['finalTotal'] as double;
              final sumNumbers = numbers.reduce((a, b) => a + b);
              final groups = <List<double>>[];
              for (int i = 0; i < numbers.length; i += 5) {
                final end = (i + 5 > numbers.length) ? numbers.length : i + 5;
                groups.add(numbers.sublist(i, end));
              }
              return ExpansionTile(
                title: Text('Phiên ${index + 1}: ${numbers.length} số'),
                subtitle: Text(
                  'Tổng số: ${_formatVND(sumNumbers).replaceAll(' VND', '')} | Tổng tính: ${_formatVND(finalTotal).replaceAll(' VND', '')}',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Các nhóm 5 số:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...groups.map((group) {
                          final groupSum = group.reduce((a, b) => a + b);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              '${group.join(', ')} | Tổng: ${_formatVND(groupSum).replaceAll(' VND', '')}',
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Text(
                          'Tổng tất cả số: ${_formatVND(sumNumbers).replaceAll(' VND', '')}',
                        ),
                        Text(
                          'Tổng sau phép tính: ${_formatVND(finalTotal).replaceAll(' VND', '')}',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <List<double>>[];
    for (int i = 0; i < _numbers.length; i += 5) {
      final end = (i + 5 > _numbers.length) ? _numbers.length : i + 5;
      groups.add(_numbers.sublist(i, end));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ứng dụng Tính Toán')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Nhập số',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addNumber,
                  child: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: groups.map((group) {
                        final sum = group.reduce((a, b) => a + b);
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              ...group.map((num) => Text(num.toString())),
                              const Divider(),
                              Text('Tổng: $sum'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    if (_lastOperation.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lastOperation,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    Row(
                      children: [
                        Text(
                          'Tổng tất cả: ${_formatVND(_totalSum).replaceAll(' VND', '')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 20),
                        DropdownButton<String>(
                          value: _operation,
                          items: ['+', '-', '*', '/'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _operation = newValue!;
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _valueController,
                            decoration: const InputDecoration(
                              labelText: 'Giá trị',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _applyOperation,
                          child: const Text('Tính'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _finalize,
                          child: const Text('Kết mã'),
                        ),
                        ElevatedButton(
                          onPressed: _reset,
                          child: const Text('Reset'),
                        ),
                        ElevatedButton(
                          onPressed: _showHistory,
                          child: const Text('Lịch sử'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
