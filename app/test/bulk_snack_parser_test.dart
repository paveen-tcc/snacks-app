import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/presentation/admin/bulk_snack_parser.dart';

void main() {
  test('parses the new nine-column layout with a whole-rupee price', () {
    final snacks = parseBulkSnacks('''
name,category,image_url,veg_or_non_veg,serving_size,share_count,price_rupees,is_active,sort_order
Tea,Drinks,https://example.com/tea.png,veg,1 Cup,2,18,true,30
''');

    expect(snacks, [
      {
        'name': 'Tea',
        'category': 'Drinks',
        'emoji': 'https://example.com/tea.png',
        'isVeg': true,
        'servingSize': '1 Cup',
        'shareCount': 2,
        'priceRupees': 18,
        'isActive': true,
        'sortOrder': 30,
      },
    ]);
  });

  for (final price in ['-1', '12.5', 'not-a-price', '']) {
    test('rejects supplied invalid price "$price" with its source row', () {
      expect(
        () => parseBulkSnacks('''
name,category,image_url,veg_or_non_veg,serving_size,share_count,price_rupees,is_active,sort_order
Tea,Drinks,,veg,1 Cup,1,$price,true,10
'''),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(contains('Row 2'), contains('price')),
          ),
        ),
      );
    });
  }

  test(
    'preserves the legacy eight-column layout and defaults price to zero',
    () {
      final snacks = parseBulkSnacks('''
name,category,image_url,veg_or_non_veg,serving_size,share_count,is_active,sort_order
Samosa,Snacks,https://example.com/samosa.png,non-veg,2 Pieces,3,false,40
''');

      expect(snacks.single, containsPair('priceRupees', 0));
      expect(snacks.single, containsPair('isActive', false));
      expect(snacks.single, containsPair('sortOrder', 40));
      expect(snacks.single, containsPair('isVeg', false));
    },
  );

  test('supports an eight-column legacy row without a header', () {
    final snacks = parseBulkSnacks('Samosa,Snacks,,veg,2 Pieces,3,true,40');

    expect(snacks.single, containsPair('priceRupees', 0));
    expect(snacks.single, containsPair('isActive', true));
    expect(snacks.single, containsPair('sortOrder', 40));
  });

  for (final input in [
    'name,category,image_url,veg_or_non_veg,serving_size,share_count,price_rupees,sort_order',
    'Tea,Drinks,,veg,1 Cup,1,true',
    'Tea,Drinks,,veg,1 Cup,1,18,true,10,extra',
  ]) {
    test('rejects ambiguous or unsupported layout: $input', () {
      expect(
        () => parseBulkSnacks(input),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('layout'),
          ),
        ),
      );
    });
  }
}
