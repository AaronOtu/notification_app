import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/models/notification_model.dart';
import 'package:notification_app/widgets/custom_text.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:notification_app/widgets/loader.dart';

// --------------------------- Providers ---------------------------

final alertStatusProvider =
    StateNotifierProvider.autoDispose<AlertStatusNotifier, AlertState>((ref) {
  return AlertStatusNotifier();
});

final apiProvider = Provider<ApiService>((ref) => ApiService());

final notificationDataProvider = StateNotifierProvider<NotificationDataNotifier,
    AsyncValue<List<NotificationModel>>>((ref) {
  final apiService = ref.watch(apiProvider);
  return NotificationDataNotifier(apiService);
});

// --------------------------- State Management ---------------------------

class AlertState {
  final bool isResolved;
  final String status;
  final bool isLoading;
  final bool wasJustResolved;

  AlertState({
    required this.isResolved,
    required this.status,
    this.isLoading = false,
    this.wasJustResolved = false,
  });

  AlertState copyWith({
    bool? isResolved,
    String? status,
    bool? isLoading,
    bool? wasJustResolved,
  }) {
    return AlertState(
      isResolved: isResolved ?? this.isResolved,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      wasJustResolved: wasJustResolved ?? this.wasJustResolved,
    );
  }
}

class AlertStatusNotifier extends StateNotifier<AlertState> {
  AlertStatusNotifier()
      : super(AlertState(isResolved: false, status: 'PENDING'));

  void setResolved(bool resolved) {
    state = state.copyWith(
      isResolved: resolved,
      status: resolved ? 'RESOLVED' : 'PENDING',
      wasJustResolved: resolved,
    );
  }

  void setStatus(String status) {
    state = state.copyWith(status: status);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

class NotificationDataNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final ApiService _apiService;

  NotificationDataNotifier(this._apiService)
      : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _apiService.fetchAlerts();
      state = AsyncValue.data(notifications);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// --------------------------- Display Page ---------------------------

class DisplayPage extends ConsumerStatefulWidget {
  final String appName;
  final String severity;
  final String status;
  final String title;
  final String body;
  final String time;
  final String id;
  final DateTime timeCreated;
  final DateTime timeResolved;

  const DisplayPage({
    super.key,
    required this.appName,
    required this.severity,
    required this.status,
    required this.title,
    required this.body,
    required this.time,
    required this.id,
    required this.timeCreated,
    required this.timeResolved,
  });

  @override
  ConsumerState<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends ConsumerState<DisplayPage> {
  bool _isNavigatingBack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertStatusProvider.notifier).setStatus(widget.status);
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(notificationDataProvider.notifier).fetchNotifications();
  }

  Future<bool> _handleBackPress() async {
    final alertState = ref.read(alertStatusProvider);
    
    if (alertState.wasJustResolved) {
      setState(() {
        _isNavigatingBack = true;
      });
      
      ref.read(alertStatusProvider.notifier).setLoading(true);
      await _handleRefresh();
      ref.read(alertStatusProvider.notifier).setLoading(false);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
    return true;
  }

  Future<void> _showResolveDialog() async {
    final alertNotifier = ref.read(alertStatusProvider.notifier);

    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Resolve Alert'),
          content: const Text('Are you sure you want to resolve this alert?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      try {
        alertNotifier.setLoading(true);
        final apiService = ref.read(apiProvider);
        final success = await apiService.resolveAlert(widget.id);

        if (success && mounted) {
          alertNotifier.setResolved(true);
          await ref.read(notificationDataProvider.notifier).fetchNotifications();
          if (mounted) {
            _showSnackBar('Alert resolved successfully!');
          }
        } else if (mounted) {
          throw Exception('Failed to resolve alert');
        }
      } catch (error) {
        if (mounted) {
          alertNotifier.setResolved(false);
          _showSnackBar('Failed to resolve alert: ${error.toString()}');
        }
      } finally {
        if (mounted) {
          alertNotifier.setLoading(false);
        }
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: message.contains('successfully') 
            ? Colors.green 
            : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final alertState = ref.watch(alertStatusProvider);

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: XcelLoader(
        isLoading: alertState.isLoading && (alertState.wasJustResolved || _isNavigatingBack),
        child: Scaffold(
          backgroundColor: Colors.grey.shade200,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBackPress,
            ),
            title: const EtzText(
              text: 'Notification Details',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.white,
          ),
          body: LiquidPullToRefresh(
            onRefresh: _handleRefresh,
            showChildOpacityTransition: false,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: screenWidth * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildInfoRow('Severity', widget.severity),
                        const SizedBox(height: 20),
                        _buildDescriptionRow(),
                        const SizedBox(height: 20),
                        _buildInfoRowWithDate('Time', widget.timeCreated),
                        const SizedBox(height: 20),
                        if (alertState.status == 'RESOLVED')
                          _buildInfoRowWithResolvedDate(
                              'Resolved at', widget.timeResolved),
                        const SizedBox(height: 20),
                        _buildInfoRow('Status', alertState.status),
                        const SizedBox(height: 20),
                        if (alertState.status == 'PENDING') _buildResolveSwitch(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Row(
            children: [
              FittedBox(
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: Image(
                    image: AssetImage('assets/etapp.png'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              EtzText(
                text: widget.appName,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                maxLines:2,
                overflow:TextOverflow.ellipsis
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            EtzText(
              text: 'Title',
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(width: 20),
            EtzText(text: widget.title),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        EtzText(
          text: label,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(width: 20),
        Expanded(child: EtzText(text: value)),
      ],
    );
  }

  Widget _buildDescriptionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EtzText(
          text: 'Description',
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: EtzText(
            text: widget.body,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithDate(String label, DateTime date) {
    String formattedDate = DateFormat('dd MMM yyyy hh:mm a').format(date);
    return _buildInfoRow(label, formattedDate);
  }

  Widget _buildInfoRowWithResolvedDate(String label, DateTime date) {
    String formattedDate = DateFormat('dd MMM yyyy hh:mm a').format(date);
    return _buildInfoRow(label, formattedDate);
  }

  Widget _buildResolveSwitch() {
    final alertState = ref.watch(alertStatusProvider);
    return Row(
      children: [
        const EtzText(text: 'Resolve',fontWeight: FontWeight.bold),
        const SizedBox(width: 8),
        Switch(
          value: alertState.isResolved,
          onChanged: alertState.isLoading
              ? null
              : (bool value) {
                  if (value) {
                    _showResolveDialog();
                  } else {
                    ref.read(alertStatusProvider.notifier).setResolved(false);
                  }
                },
        ),
      ],
    );
  }
}