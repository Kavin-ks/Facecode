import 'package:flutter/material.dart';
import 'package:facecode/services/network_connectivity_service.dart';
import 'package:facecode/utils/constants.dart';

/// Widget that handles retry logic for network operations
class NetworkRetryWrapper extends StatefulWidget {
  final Future<void> Function() operation;
  final Widget Function(BuildContext context, VoidCallback retry) errorBuilder;
  final Widget Function(BuildContext context) successBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;

  const NetworkRetryWrapper({
    super.key,
    required this.operation,
    required this.errorBuilder,
    required this.successBuilder,
    this.loadingBuilder,
  });

  @override
  State<NetworkRetryWrapper> createState() => _NetworkRetryWrapperState();
}

class _NetworkRetryWrapperState extends State<NetworkRetryWrapper> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _executeOperation();
  }

  Future<void> _executeOperation() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await NetworkConnectivityService().retryOperation(
        operation: widget.operation,
        maxAttempts: 3,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _retry() {
    _executeOperation();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingBuilder?.call(context) ?? _buildDefaultLoading();
    }

    if (_hasError) {
      return widget.errorBuilder(context, _retry);
    }

    return widget.successBuilder(context);
  }

  Widget _buildDefaultLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// Simple error widget with retry button
class NetworkErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final IconData icon;

  const NetworkErrorWidget({
    super.key,
    this.message,
    required this.onRetry,
    this.icon = Icons.cloud_off,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppConstants.errorColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Connection failed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
