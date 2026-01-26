import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facecode/utils/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Friendly error screen shown when an error occurs
class ErrorFallbackScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;
  final String? context;

  const ErrorFallbackScreen({
    super.key,
    required this.error,
    this.stackTrace,
    required this.onRetry,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon with Animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppConstants.errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppConstants.errorColor,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2.seconds, color: AppConstants.errorColor.withValues(alpha: 0.3)),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Description
              Text(
                "Don't worry, we've got this! Try one of the options below.",
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 40),

              // Action Buttons
              _buildActionButton(
                icon: Icons.refresh,
                label: 'Try Again',
                color: AppConstants.primaryColor,
                onPressed: onRetry,
              ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

              const SizedBox(height: 12),

              _buildActionButton(
                icon: Icons.home,
                label: 'Go to Home',
                color: AppConstants.secondaryColor,
                onPressed: () {
                  // Pop until we reach home or root
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0),

              const SizedBox(height: 32),

              // Error Details (Expandable)
              _ErrorDetailsExpander(
                error: error,
                stackTrace: stackTrace,
                context: this.context,
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _ErrorDetailsExpander extends StatefulWidget {
  final Object error;
  final StackTrace? stackTrace;
  final String? context;

  const _ErrorDetailsExpander({
    required this.error,
    this.stackTrace,
    this.context,
  });

  @override
  State<_ErrorDetailsExpander> createState() => _ErrorDetailsExpanderState();
}

class _ErrorDetailsExpanderState extends State<_ErrorDetailsExpander> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: AppConstants.textMuted,
          ),
          label: Text(
            _isExpanded ? 'Hide Details' : 'Show Error Details',
            style: const TextStyle(
              color: AppConstants.textMuted,
              fontSize: 14,
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.errorColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.context != null) ...[
                  _buildDetailRow('Context', widget.context!),
                  const SizedBox(height: 8),
                ],
                _buildDetailRow('Error', widget.error.toString()),
                if (widget.stackTrace != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Stack Trace',
                        style: TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        color: AppConstants.textMuted,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.stackTrace.toString()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stack trace copied'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.stackTrace.toString(),
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
