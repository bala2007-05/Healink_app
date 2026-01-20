import 'package:intl/intl.dart';

class FormatUtils {
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }
  
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  static String formatDripRate(double rate) {
    return '${rate.toStringAsFixed(1)} ml/hr';
  }
  
  static String formatBattery(int level) {
    return '$level%';
  }

  static String formatActiveTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • HH:mm:ss').format(dateTime);
  }

  static String formatDeactiveTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • HH:mm:ss').format(dateTime);
  }

  static String formatTimeWithSeconds(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  static String formatDateAndTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }
}

