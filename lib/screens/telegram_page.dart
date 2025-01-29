import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/notifiers/telegram_notifiers.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:notification_app/widgets/loader.dart';

final isFirstVisitProvider = StateProvider<bool>((ref)=> true);
final telegramLoadingProvider = StateProvider<bool>((ref)=>false);

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
         
         if(isFirstVisit){
        ref.read(telegramLoadingProvider.notifier).state = true;
        await ref.read(telegramProvider.notifier).fetchTelegram();
        ref.read(telegramLoadingProvider.notifier).state = false;
        ref.read(isFirstVisitProvider.notifier).state =false;
         }
         else{
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
     ref.read(telegramLoadingProvider.notifier).state =true;
    await ref.read(telegramProvider.notifier).fetchTelegram();
     ref.read(telegramLoadingProvider.notifier).state = false;
    
  }

  void _showAddTelegramDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Image(
              image: AssetImage('assets/link.png'),
              height: 24,
              width: 24,
            ),
            SizedBox(width: 10),
            EtzText(text:'Telegram chat_id'),
          ],
        ),
        content: TextField(
          controller: _telegramController,
          decoration: InputDecoration(
            labelText: 'Telegram chat_id',
            hintText: 'Enter chat_id',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            label:  EtzText(text:'Cancel', color:Colors.black),
        
          ),
          TextButton.icon(
            onPressed: () async {
              if (_telegramController.text.isNotEmpty) {
                ref.read(telegramLoadingProvider.notifier).state = true;

                await ref.read(telegramProvider.notifier).addTelegram(_telegramController.text);
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
            },
            //icon: const Icon(Icons.add),
            label:EtzText(text:'Add', color:Colors.black),
      
          ),
        ],
      ),
    );
  }

  void _showDeleteTelegramDialog(String id, String telegramContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Image(
              image: AssetImage('assets/high.png'),
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 10),
            EtzText(text:'Delete chat_id', color: Colors.red[700]),
          ],
        ),
        content: EtzText(
          text:'Are you sure you want to delete "$telegramContent"?',fontSize: 16,
      // style: const TextStyle(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
        
            label: EtzText(text:'Cancel', color: Colors.black),
    
          ),
          TextButton.icon(
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

            label:EtzText(text:'Delete', color:Colors.black),
    
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telegramList = ref.watch(telegramProvider);
    final isLoading = ref.watch(telegramLoadingProvider);
    final filteredTelegramList = telegramList
        .where((telegram) =>
            telegram.telegram
                ?.toLowerCase()
                .contains(_searchController.text.toLowerCase()) ??
            false)
        .toList();

    return XcelLoader(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const EtzText(
              text: 'Telegram Management', fontWeight: FontWeight.bold),
          elevation: 2,
        ),
        body: LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          showChildOpacityTransition: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Search telegram chat_id...',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: const Image(
                                image: AssetImage('assets/search.png'),
                                height: 10,
                                width: 10,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.0
                              )
                            ),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _showAddTelegramDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Image(
                            image: AssetImage('assets/add_telegram.png'),
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 8),
                          EtzText(
                            text: 'Add Telegram (${telegramList.length})',
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredTelegramList.isEmpty
                    ? _buildEmptyState()
                    : _buildTelegramList(filteredTelegramList),
              ),
            ],
          ),
        ),
      ),
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
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Image(
                image: AssetImage('assets/link.png'),
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
                onPressed: () => _showDeleteTelegramDialog(
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