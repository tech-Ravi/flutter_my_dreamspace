class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Auth Errors
    if (errorString.contains('invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (errorString.contains('email not confirmed')) {
      return 'Please confirm your email address';
    }
    if (errorString.contains('email already registered')) {
      return 'This email is already registered';
    }
    if (errorString.contains('invalid email')) {
      return 'Please enter a valid email address';
    }
    if (errorString.contains('password')) {
      return 'Please check your password';
    }
    if (errorString.contains('auth')) {
      return 'Authentication failed. Please try again';
    }

    // Network ErRors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection';
    }
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again';
    }

    // Permission Errors
    if (errorString.contains('not authenticated')) {
      return 'Please sign in to continue';
    }
    if (errorString.contains('permission') ||
        errorString.contains('unauthorized')) {
      return 'You don\'t have permission to perform this action';
    }

    // Resource Errors
    if (errorString.contains('not found')) {
      return 'Resource not found';
    }
    if (errorString.contains('duplicate')) {
      return 'This item already exists';
    }

    // Validation Errors
    if (errorString.contains('validation')) {
      return 'Please check your input';
    }

    // Servers Errors
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later';
    }

    // DefaulT Error
    return 'Something went wrong. Please try again';
  }
}
