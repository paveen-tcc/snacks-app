import 'package:flutter/material.dart';
import '../../core/theme/notion_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock history data
    final history = [
      {'date': 'Today', 'snack': 'Samosa', 'status': 'Ordered'},
      {'date': 'Yesterday', 'snack': 'Chicken Puff', 'status': 'Delivered'},
      {'date': 'Wed, Feb 14', 'snack': 'Vada Pav', 'status': 'Delivered'},
      {
        'date': 'Tue, Feb 13',
        'snack': 'Default (Samosa)',
        'status': 'Delivered',
      },
      {'date': 'Mon, Feb 12', 'snack': 'Chicken Puff', 'status': 'Delivered'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final item = history[index];
          final isToday = item['date'] == 'Today';

          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              item['date']!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? NotionTheme.blueAccent
                    : NotionTheme.primaryText,
              ),
            ),
            subtitle: Text(
              item['snack']!,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NotionTheme.surfaceHover,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item['status']!,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}
