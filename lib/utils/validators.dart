class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[0-9]{10,}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validatePatientId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Patient ID is required';
    }
    if (value.length < 3) {
      return 'Patient ID must be at least 3 characters';
    }
    return null;
  }

  static String? validateRoomNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Room number is required';
    }
    return null;
  }

  static String? validateEmployeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Employee ID is required';
    }
    if (value.length < 3) {
      return 'Employee ID must be at least 3 characters';
    }
    return null;
  }

  static String? validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    if (value.length < 5) {
      return 'License number must be at least 5 characters';
    }
    return null;
  }

  static String? validateDepartment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Department is required';
    }
    return null;
  }

  static String? validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    return null;
  }

  static String? validateEmergencyContact(String? value) {
    if (value == null || value.isEmpty) {
      return 'Emergency contact is required';
    }
    return null;
  }
}

