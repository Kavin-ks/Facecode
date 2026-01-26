import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';

/// Development widget to test error handling
/// Add this button anywhere in debug builds to test error scenarios
class ErrorTestButton extends StatelessWidget {
  const ErrorTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            // Test synchronous widget error
            throw Exception('Test widget error - this should show error fallback screen');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.errorColor,
          ),
          child: const Text('Trigger Widget Error'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            // Test asynchronous error
            await Future.delayed(const Duration(milliseconds: 500));
            throw Exception('Test async error - this should be logged');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.warningColor,
          ),
          child: const Text('Trigger Async Error'),
        ),
      ],
    );
  }
}
