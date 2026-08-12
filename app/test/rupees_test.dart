import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/core/formatters/rupees.dart';

void main() {
  test('whole rupees reject fractions and negatives', () {
    expect(parseWholeRupees('0'), 0);
    expect(parseWholeRupees('125'), 125);
    expect(parseWholeRupees('-1'), isNull);
    expect(parseWholeRupees('12.5'), isNull);
    expect(formatRupees(125), '₹125');
  });
}
