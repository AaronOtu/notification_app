import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:notification_app/api/notifiers/Sms_notifiers.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:notification_app/widgets/add_dialog.dart';
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

  void _showdDeleteDialog(String id, String smsContent) {
    showDialog(
      context: context,
      builder: (context) => showDialogs(
        title: 'Delete Number',
        image: 'assets/delete.png',
        isDelete: true,
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
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
        context: context,
        builder: (context) => showDialogs(
            isDelete: false,
            hintText: '05508070111',
            title: 'Add Sms',
            image: 'assets/sms1.png',
            controller: _smsController,
            keyboardType: TextInputType.phone,
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
            }));
  }

  @override
  Widget build(BuildContext context) {
    final smsList = ref.watch(smsProvider);
    //final isLoading = ref.watch(smsLoadingProvider);
    final filteredSmsList = smsList
        .where((sms) =>
            sms.sms
                ?.toLowerCase()
                .contains(_searchController.text.toLowerCase()) ??
            false)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            const EtzText(text: 'SMS Management', fontWeight: FontWeight.bold),
        elevation: 2,
      ),
      body: Stack(children: [
        LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          showChildOpacityTransition: false,
          child: Column(
            children: [
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: SizedBox(
                        height: 60,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Search phone numbers',
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
                  const SizedBox(width: 16),
                ],
              ),
              Expanded(
                child: filteredSmsList.isEmpty
                    ? _buildEmptyState()
                    : _buildSmsList(filteredSmsList),
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
                      text: 'Add Sms',
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
            color: Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Image(
                image: AssetImage('assets/sms1.png'),
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
                onPressed: () => _showdDeleteDialog(
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
