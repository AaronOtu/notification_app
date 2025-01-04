import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/notifiers/Sms_notifiers.dart';

class SmsPage extends ConsumerStatefulWidget {
  const SmsPage({super.key});

  @override
  ConsumerState<SmsPage> createState() => _SmsPageState();
}

class _SmsPageState extends ConsumerState<SmsPage> {
  final TextEditingController _smsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(smsProvider.notifier).fetchSms());
  }

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _refreshSms() async {
    setState(() => _isLoading = true);
    await ref.read(smsProvider.notifier).fetchSms();
    setState(() => _isLoading = false);
  }

  void _showAddSmsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.message_outlined, color: Colors.green),
            SizedBox(width: 10),
            Text('Add New SMS'),
          ],
        ),
        content: TextField(
          controller: _smsController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter phone number',
            prefixIcon: const Icon(Icons.phone_android),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (_smsController.text.isNotEmpty) {
                await ref.read(smsProvider.notifier).addSms(_smsController.text);
                _smsController.clear();
                await ref.read(smsProvider.notifier).fetchSms();
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
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSmsDialog(String id, String smsContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text('Delete Number', style: TextStyle(color: Colors.red[700])),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$smsContent"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(smsProvider.notifier).deleteSms(id);
              await ref.read(smsProvider.notifier).fetchSms();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final smsList = ref.watch(smsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Management'),
        elevation: 2,
        actions: [
          IconButton(
            icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshSms,
          ),
        ],
      ),
      body: Column(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddSmsDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Number'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${smsList.length} Numbers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: smsList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No phone numbers added yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: smsList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sms = smsList[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Icon(
                              Icons.phone_android,
                              color: Colors.green[700],
                            ),
                          ),
                          title: Text(
                            sms.sms ?? 'No number',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            onPressed: () => _showDeleteSmsDialog(
                              sms.id ?? '',
                              sms.sms ?? '',
                            ),
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