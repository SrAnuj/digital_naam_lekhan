import 'package:flutter_test/flutter_test.dart';
import 'package:sankalp/theme.dart';

void main() {
  test('Indian number formatting', () {
    expect(fmt(1008), '1,008');
    expect(fmt(21000), '21,000');
    expect(fmt(100000), '1,00,000');
    expect(fmt(8558), '8,558');
  });
}
