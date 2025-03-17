import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/notifiers/telegram_notifiers.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:notification_app/widgets/add_dialog.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:notification_app/widgets/loader.dart';

final isFirstVisitProvider = StateProvider<bool>((ref) => true);
final telegramLoadingProvider = StateProvider<bool>((ref) => false);

class TelegramPage extends ConsumerStatefulWidget {
  const TelegramPage({super.key});

  @override
  ConsumerState<TelegramPage> createState() => _TelegramPageState();
}

class _TelegramPageState extends ConsumerState<TelegramPage> {
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final isFirstVisit = ref.read(isFirstVisitProvider);

      if (isFirstVisit) {
        ref.read(telegramLoadingProvider.notifier).state = true;
        await ref.read(telegramProvider.notifier).fetchTelegram();
        ref.read(telegramLoadingProvider.notifier).state = false;
        ref.read(isFirstVisitProvider.notifier).state = false;
      } else {
        await ref.read(telegramProvider.notifier).fetchTelegram();
      }
    });
  }

  @override
  void dispose() {
    _telegramController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.read(telegramLoadingProvider.notifier).state = true;
    await ref.read(telegramProvider.notifier).fetchTelegram();
    ref.read(telegramLoadingProvider.notifier).state = false;
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => showDialogs(
          isDelete: false,
          hintText: '-100123456789',
          controller: _telegramController,
          image: 'assets/telegrams.png',
          title: 'Add Telegram chat_id',
          onPressed: () async {
            if (_telegramController.text.isNotEmpty) {
              ref.read(telegramLoadingProvider.notifier).state = true;

              await ref
                  .read(telegramProvider.notifier)
                  .addTelegram(_telegramController.text);
              await ref.read(telegramProvider.notifier).fetchTelegram();

              ref.read(telegramLoadingProvider.notifier).state = false;

              _telegramController.clear();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Telegram chat_id added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }),
    );
  }

  void _showDeleteDialog(String id, String telegramContent) {
    showDialog(
        context: context,
        builder: (context) => showDialogs(
              isDelete: true,
              image: 'assets/delete.png',
              title: 'Delete chat_id',
              onPressed: () async {
                ref.read(telegramLoadingProvider.notifier).state = true;
                await ref.read(telegramProvider.notifier).deleteTelegram(id);
                await ref.read(telegramProvider.notifier).fetchTelegram();
                ref.read(telegramLoadingProvider.notifier).state = false;
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Telegram chat_id deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ));
  }

  @override
  Widget build(BuildContext context) {
    final telegramList = ref.watch(telegramProvider);
    //final isLoading = ref.watch(telegramLoadingProvider);
    final filteredTelegramList = telegramList
        .where((telegram) =>
            telegram.telegram
                ?.toLowerCase()
                .contains(_searchController.text.toLowerCase()) ??
            false)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const EtzText(
            text: 'Telegram Management', fontWeight: FontWeight.bold),
        elevation: 2,
      ),
      body: Stack(children: [
        LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          showChildOpacityTransition: false,
          child: Column(
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left:16.0,right:16),
                      child: SizedBox(
                        height: 60,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Search chat_id',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'assets/search1.png',
                                height: 10,
                                width: 10,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                  color: Color(0xFFF4F6F9), width: 0.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade500, width: 1.0),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                  color: Color(0xFFF4F6F9), width: 0.5),
                            ),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: filteredTelegramList.isEmpty
                    ? _buildEmptyState()
                    : _buildTelegramList(filteredTelegramList),
              ),
            ],
          ),
        ),
        Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                height: 40,
                width: 120,
                child: ElevatedButton(
                    onPressed: _showAddDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF000000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: EtzText(
                      text: 'Add chat_id',
                      color: Colors.white,
                    )),
              ),
            ))
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Image(
            image: AssetImage('assets/empty_notification.png'),
            height: 64,
            width: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No telegram chat_id added yet'
                : 'No matching chat_id found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramList(List<dynamic> telegramList) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: telegramList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final telegram = telegramList[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Image(
                image: AssetImage('assets/telegrams.png'),
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  telegram.telegram ?? 'No chat_id',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Image(
                  image: AssetImage('assets/delete.png'),
                  height: 24,
                  width: 24,
                ),
                onPressed: () => _showDeleteDialog(
                  telegram.id ?? '',
                  telegram.telegram ?? '',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
