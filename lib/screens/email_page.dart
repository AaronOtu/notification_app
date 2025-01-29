import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/notifiers/email_notifiers.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:notification_app/widgets/loader.dart';

final isFirstVisitProvider = StateProvider<bool>((ref) => true);
final emailLoadingProvider = StateProvider<bool>((ref) => false);

class EmailPage extends ConsumerStatefulWidget {
  const EmailPage({super.key});

  @override
  ConsumerState<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends ConsumerState<EmailPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final isFirstVisit = ref.read(isFirstVisitProvider);

      if (isFirstVisit) {
        ref.read(emailLoadingProvider.notifier).state = true;
        await ref.read(emailsProvider.notifier).fetchEmails();
        ref.read(emailLoadingProvider.notifier).state = false;
        ref.read(isFirstVisitProvider.notifier).state = false;
      } else {
        await ref.read(emailsProvider.notifier).fetchEmails();
      }

    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.read(emailLoadingProvider.notifier).state = true;
  
    await ref.read(emailsProvider.notifier).fetchEmails();

    ref.read(emailLoadingProvider.notifier).state = false;
 
  }

  void _showAddEmailDialog() {
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
              image: AssetImage('assets/mail.png'),
              height: 24,
              width: 24,
            ),
            SizedBox(width: 10),
            EtzText(text: 'Email'),
          ],
        ),
        content: TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
        
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
       
            label: EtzText(text: 'Cancel', color: Colors.black),
         
          ),
          TextButton.icon(
            onPressed: () async {
              if (_emailController.text.isNotEmpty) {
                ref.read(emailLoadingProvider.notifier).state = true;
                await ref
                    .read(emailsProvider.notifier)
                    .addEmail(_emailController.text);
                await ref.read(emailsProvider.notifier).fetchEmails();

                ref.read(emailLoadingProvider.notifier).state = false;
                _emailController.clear();
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
    
            label: EtzText(text: 'Add', color: Colors.black),
         
          ),
        ],
      ),
    );
  }

  void _showDeleteEmailDialog(String id, String email) {
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
            EtzText(text: 'Delete Email', color: Colors.red[700]),
          ],
        ),
        content: EtzText(
          text: 'Are you sure you want to delete $email?', fontSize: 16,
          //style: const TextStyle(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            //icon: const Icon(Icons.close),
            label: EtzText(text: 'Cancel', color: Colors.black),
            // style: TextButton.styleFrom(
            //   foregroundColor: Colors.grey,
            // ),
          ),
          TextButton.icon(
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
       
            label: EtzText(text: 'Delete', color: Colors.black),
       
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emails = ref.watch(emailsProvider);
    final isLoading = ref.watch(emailLoadingProvider);
    final filteredEmails = emails
        .where((email) =>
            email.email
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
              text: 'Email Management', fontWeight: FontWeight.bold),
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
                        height: 48, // Match button height
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                          
        
                            hintText: 'Search emails...',
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
                      onPressed: _showAddEmailDialog,
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
                            image: AssetImage('assets/add_email.png'),
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 8),
                          EtzText(
                            text: 'Add email (${emails.length})',
                            color: Colors.black,
                          ),
                        ],
                      ),
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
          const Image(
            image: AssetImage('assets/empty_notification.png'),
            height: 64,
            width: 64,
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Image(
                image: AssetImage('assets/email.png'),
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  email.email ?? 'No email',
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
                onPressed: () => _showDeleteEmailDialog(
                  email.id ?? '',
                  email.email ?? '',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
