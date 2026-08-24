import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/core/constants/food_assets.dart';

void main() {
  test('every mapped food and drink image exists in a mobile-safe format', () {
    final paths = localFoodAssetMap.values.toSet();

    expect(paths, isNotEmpty);
    for (final path in paths) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: 'Missing mapped asset: $path',
      );
      expect(
        path.endsWith('.webp') || path.endsWith('.jpg'),
        isTrue,
        reason: 'Unexpected raster format: $path',
      );
    }
  });
}
