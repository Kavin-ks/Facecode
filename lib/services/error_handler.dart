import 'package:facecode/models/game_error.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class ErrorHandler {
  static GameError map(dynamic error) {
    // Default Unknown Error
    GameError mappedError = const GameError(
      type: GameErrorType.unknown,
      title: "Something went wrong",
      message: "An unexpected error occurred. Please try again.",
      actionLabel: "Retry",
    );

    if (error is SocketException) {
      mappedError = const GameError(
        type: GameErrorType.network,
        title: "No Internet Connection",
        message: "Please check your network settings and try again.",
        actionLabel: "Retry",
      );
    } 
    else if (error is FirebaseAuthException) {
      mappedError = _mapAuthError(error);
    }
    else if (error is GameError) {
      return error; // Already mapped or manually thrown
    }
    // Add more mappings here as needed

    return mappedError;
  }

  static GameError _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return const GameError(
          type: GameErrorType.validation,
          title: "Incorrect Credentials",
          message: "The email or password you entered is incorrect. Please try again.",
          actionLabel: "Try Again",
        );
      case 'email-already-in-use':
        return const GameError(
          type: GameErrorType.validation,
          title: "Email Taken",
          message: "This email is already associated with an account. Try logging in instead.",
          actionLabel: "Log In",
        );
      case 'network-request-failed':
        return const GameError(
          type: GameErrorType.network,
          title: "Network Error",
          message: "Unable to reach the server. Please check your connection.",
          actionLabel: "Retry",
        );
      case 'too-many-requests':
        return const GameError(
          type: GameErrorType.network,
          title: "Hold on!",
          message: "We've blocked requests from this device due to unusual activity. Try again later.",
          actionLabel: "OK",
        );
      default:
        return GameError(
          type: GameErrorType.unknown,
          title: "Authentication Error",
          message: error.message ?? "We couldn't verify your account.",
        );
    }
  }
}
