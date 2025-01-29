import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/notifiers/Sms_notifiers.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:notification_app/widgets/loader.dart';

final isFirstVisitProvider = StateProvider<bool>((ref) => true);
final smsLoadingProvider = StateProvider<bool>((ref) => false);

class SmsPage extends ConsumerStatefulWidget {
  const SmsPage({super.key});

  @override
  ConsumerState<SmsPage> createState() => _SmsPageState();
}

class _SmsPageState extends ConsumerState<SmsPage> {
  final TextEditingController _smsController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();



  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final isFirstVisit = ref.read(isFirstVisitProvider);

      if (isFirstVisit) {
        ref.read(smsLoadingProvider.notifier).state = true;
        await ref.read(smsProvider.notifier).fetchSms();
        ref.read(smsLoadingProvider.notifier).state = false;
        ref.read(isFirstVisitProvider.notifier).state = false;
      } else {
        await ref.read(smsProvider.notifier).fetchSms();
      }
    });
  }

  

  @override
  void dispose() {
    _smsController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _handleRefresh() async {
    ref.read(smsLoadingProvider.notifier).state = true;
    await ref.read(smsProvider.notifier).fetchSms();
    ref.read(smsLoadingProvider.notifier).state = false;
  }

  void _showAddSmsDialog() {
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
              image: AssetImage('assets/phone.png'),
              height: 24,
              width: 24,
            ),
            SizedBox(width: 10),
            EtzText(text: 'SMS'),
          ],
        ),
        content: TextField(
          controller: _smsController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter phone number',
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
            //icon: const Icon(Icons.close),
            label: EtzText(text: 'Cancel', color: Colors.black),
   
          ),
          TextButton.icon(
           

            onPressed: () async {
              if (_smsController.text.isNotEmpty) {
                // Show loading while adding
                ref.read(smsLoadingProvider.notifier).state = true;

                await ref
                    .read(smsProvider.notifier)
                    .addSms(_smsController.text);
                await ref.read(smsProvider.notifier).fetchSms();

                // Hide loading after update
                ref.read(smsLoadingProvider.notifier).state = false;

                _smsController.clear();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },

            label: EtzText(text: 'Add', color: Colors.black),
       
          ),
        ],
      ),
    );
  }

  void _showDeleteSmsDialog(String id, String smsContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
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
            EtzText(text: 'Delete Number', color: Colors.red[700]),
          ],
        ),
        content: EtzText(
            text: 'Are you sure you want to delete "$smsContent"?',
            fontSize: 16),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            //icon: const Icon(Icons.close),
            label: EtzText(text: 'Cancel', color: Colors.black),
       
          ),
          TextButton.icon(
            onPressed: () async {
              ref.read(smsLoadingProvider.notifier).state = true;
              await ref.read(smsProvider.notifier).deleteSms(id);
              await ref.read(smsProvider.notifier).fetchSms();
              ref.read(smsLoadingProvider.notifier).state = false;
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: EtzText(text: 'Phone number deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
         
            label: EtzText(text: 'Delete', color: Colors.black),
   
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final smsList = ref.watch(smsProvider);
    final isLoading = ref.watch(smsLoadingProvider);
    final filteredSmsList = smsList
        .where((sms) =>
            sms.sms
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
              text: 'SMS Management', fontWeight: FontWeight.bold),
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
                            hintText: 'Search phone numbers...',
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
                                    color: Colors.grey.shade300, width: 1.0)),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _showAddSmsDialog,
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
                            image: AssetImage('assets/add_sms.png'),
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 8),
                          EtzText(
                            text: 'Add SMS (${smsList.length})',
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredSmsList.isEmpty
                    ? _buildEmptyState()
                    : _buildSmsList(filteredSmsList),
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
                ? 'No phone numbers added yet'
                : 'No matching numbers found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmsList(List<dynamic> smsList) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: smsList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sms = smsList[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Image(
                image: AssetImage('assets/phone.png'),
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  sms.sms ?? 'No number',
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
                onPressed: () => _showDeleteSmsDialog(
                  sms.id ?? '',
                  sms.sms ?? '',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
