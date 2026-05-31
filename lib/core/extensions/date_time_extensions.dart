import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String get formatted => DateFormat('dd MMM yyyy').format(this);
  String get formattedWithTime => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String get timeOnly => DateFormat('hh:mm a').format(this);
  String get dateOnly => DateFormat('dd/MM/yyyy').format(this);

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
