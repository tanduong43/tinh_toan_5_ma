import 'package:get/get.dart';

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
