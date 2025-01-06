
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/notifiers/email_notifiers.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:notification_app/widgets/loader.dart';

class EmailPage extends ConsumerStatefulWidget {
  const EmailPage({super.key});

  @override
  ConsumerState<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends ConsumerState<EmailPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(emailsProvider.notifier).fetchEmails());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await ref.read(emailsProvider.notifier).fetchEmails();
    setState(() => _isLoading = false);
  }

  void _showAddEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: Colors.blue),
            SizedBox(width: 10),
            Text('Add New Email'),
          ],
        ),
        content: TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter email address',
            prefixIcon: const Icon(Icons.mail_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
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
              if (_emailController.text.isNotEmpty) {
                await ref.read(emailsProvider.notifier).addEmail(_emailController.text);
                _emailController.clear();
                await ref.read(emailsProvider.notifier).fetchEmails();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteEmailDialog(String id, String email) {
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
            Text('Delete Email', style: TextStyle(color: Colors.red[700])),
          ],
        ),
        content: Text(
          'Are you sure you want to delete $email?',
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
              await ref.read(emailsProvider.notifier).deleteEmail(id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emails = ref.watch(emailsProvider);
    final filteredEmails = emails.where((email) => 
      email.email?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false
    ).toList();

    return XcelLoader(
      isLoading: _isLoading,
      child: Scaffold(
       backgroundColor:Colors.white,
        appBar: AppBar(
          backgroundColor:Colors.white,
          title: const Text('Email Management'),
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
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search emails...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Stack(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showAddEmailDialog,
                          icon: const Icon(Icons.email),
                          label: const Text('New Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12
                            ),
                          ),
                        ),
                        if (emails.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${emails.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredEmails.isEmpty
                    ? _buildEmptyState()
                    : _buildEmailList(filteredEmails),
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
          Icon(
            Icons.mail_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty 
                ? 'No emails added yet'
                : 'No matching emails found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailList(List<dynamic> emails) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: emails.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final email = emails[index];
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
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.mail,
                color: Colors.white,
              ),
            ),
            title: Text(
              email.email ?? 'No email',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: () => _showDeleteEmailDialog(
                email.id ?? '',
                email.email ?? '',
              ),
            ),
          ),
        );
      },
    );
  }
}

