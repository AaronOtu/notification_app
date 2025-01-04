import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_app/api/api_service.dart';
import 'package:notification_app/api/models/notification_model.dart';
import 'package:notification_app/widgets/custom_text.dart';

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

  AlertState({
    required this.isResolved,
    required this.status,
    this.isLoading = false,
  });

  AlertState copyWith({
    bool? isResolved,
    String? status,
    bool? isLoading,
  }) {
    return AlertState(
      isResolved: isResolved ?? this.isResolved,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
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

  const DisplayPage({
    super.key,
    required this.appName,
    required this.severity,
    required this.status,
    required this.title,
    required this.body,
    required this.time,
    required this.id,
  });

  @override
  ConsumerState<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends ConsumerState<DisplayPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertStatusProvider.notifier).setStatus(widget.status);
    });
  }

  // --------------------------- Resolve Alert Dialog ---------------------------
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
            // Pop back to homepage with refresh flag
            Navigator.of(context).pop(true);
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
      SnackBar(content: Text(message)),
    );
  }

  // --------------------------- Build UI ---------------------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final alertState = ref.watch(alertStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const EtzText(
          text: 'Notification Details',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationDataProvider.notifier).fetchNotifications();
        },
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
              child: Stack(
                children: [
                  Padding(
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
                        _buildInfoRow('Time', widget.time),
                        const SizedBox(height: 20),
                        _buildInfoRow('Status', alertState.status),
                        const SizedBox(height: 20),
                        if (alertState.status == 'PENDING') _buildResolveSwitch(),
                      ],
                    ),
                  ),
                  if (alertState.isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
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
          child: EtzText(
            text: widget.appName,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        EtzText(text: widget.title),
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

  Widget _buildResolveSwitch() {
    final alertState = ref.watch(alertStatusProvider);
    return Row(
      children: [
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
        const SizedBox(width: 8),
        const EtzText(text: 'Resolve'),
      ],
    );
  }
}