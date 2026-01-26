import 'package:flutter/material.dart';
import 'package:facecode/services/error_handler_service.dart';
import 'package:facecode/widgets/error_fallback_screen.dart';

/// Error boundary widget that catches errors in its subtree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace, VoidCallback retry)? errorBuilder;
  final String? context;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.context,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _error = null;
    _stackTrace = null;
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!, _stackTrace, _retry) ??
          ErrorFallbackScreen(
            error: _error!,
            stackTrace: _stackTrace,
            onRetry: _retry,
            context: widget.context,
          );
    }

    return ErrorCatcher(
      onError: (error, stack) {
        ErrorHandlerService().reportError(
          error,
          stackTrace: stack,
          context: widget.context ?? 'Widget Error',
        );
        setState(() {
          _error = error;
          _stackTrace = stack;
        });
      },
      child: widget.child,
    );
  }
}

/// Catches errors in the widget tree
class ErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stack) onError;

  const ErrorCatcher({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stack) {
          onError(error, stack);
          rethrow;
        }
      },
    );
  }
}
