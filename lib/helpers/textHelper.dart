import 'package:intl/intl.dart';

String timeStampToString(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  } else {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

String dateToString(DateTime date) {
  return DateFormat("d MMM yyyy").format(date);
}

String formatDate(String dateStr) {
  // Parse the input string into a DateTime object
  DateTime date = DateTime.parse(dateStr);

  // Format the date as "21 Sep 2025"
  return DateFormat('dd MMM yyyy').format(date);
}
