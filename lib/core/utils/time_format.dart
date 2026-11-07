import 'package:intl/intl.dart';

abstract final class TimeFormat {
  static String relative(DateTime time, {DateTime? now}) {
    final gap = (now ?? DateTime.now()).difference(time);
    if (gap.inMinutes < 1) return 'Just now';
    if (gap.inHours < 1) return '${gap.inMinutes}m ago';
    if (gap.inDays < 1) return '${gap.inHours}h ago';
    if (gap.inDays < 7) return '${gap.inDays}d ago';
    return DateFormat('d MMM').format(time);
  }

  static String full(DateTime time) => DateFormat('d MMM yyyy, HH:mm').format(time);
}
