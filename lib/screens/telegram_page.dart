import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/notifiers/telegram_notifiers.dart';

class TelegramPage extends ConsumerStatefulWidget {
  const TelegramPage({super.key});

  @override
  ConsumerState<TelegramPage> createState() => _TelegramPageState();
}

class _TelegramPageState extends ConsumerState<TelegramPage> {
  final TextEditingController _telegramController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch Telegram messages on initial load
    Future.microtask(() => ref.read(telegramProvider.notifier).fetchTelegram());
  }

  @override
  void dispose() {
    _telegramController.dispose();
    super.dispose();
  }

  /// Show Dialog to Add Telegram Message
  void _showAddTelegramDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Telegram Link'),
        content: TextField(
          controller: _telegramController,
          decoration: const InputDecoration(
            labelText: 'Telegram Link',
            hintText: 'Enter Telegram Link',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_telegramController.text.isNotEmpty) {
                await ref.read(telegramProvider.notifier).addTelegram(_telegramController.text);
                _telegramController.clear();
                await ref.read(telegramProvider.notifier).fetchTelegram(); // Refresh Telegram list
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Show Dialog to Delete Telegram Message
  void _showDeleteTelegramDialog(String id, String telegramContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Telegram Link'),
        content: Text('Are you sure you want to delete "$telegramContent"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(telegramProvider.notifier).deleteTelegram(id);
              await ref.read(telegramProvider.notifier).fetchTelegram(); // Refresh Telegram list
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telegramList = ref.watch(telegramProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddTelegramDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Telegram'),
                ),
                Text(
                  '${telegramList.length} Links',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: telegramList.isEmpty
                ? const Center(
                    child: Text('No Telegram link added yet'),
                  )
                : ListView.separated(
                    itemCount: telegramList.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final telegram = telegramList[index];
                      return ListTile(
                        title: Text(telegram.telegram ?? 'No Link'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteTelegramDialog(
                            telegram.id ?? '',
                            telegram.telegram ?? '',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
