import 'package:intl/intl.dart';

/// Extension on DateTime to provide various formatting options using intl
extension DateTimeFormatter on DateTime {
  /// Formats date as: "January 15, 2024"
  String get toLongDate => DateFormat('MMMM d, y').format(this);

  /// Formats date as: "Jan 15, 2024"
  String get toMediumDate => DateFormat('MMM d, y').format(this);

  /// Formats date as: "01/15/2024"
  String get toShortDate => DateFormat('MM/dd/yyyy').format(this);

  /// Formats date as: "2024-01-15"
  String get toIsoDate => DateFormat('yyyy-MM-dd').format(this);

  /// Formats date as: "15 January 2024"
  String get toDayMonthYear => DateFormat('d MMMM y').format(this);

  /// Formats date as: "Jan 15"
  String get toShortDateNoYear => DateFormat('MMM d').format(this);

  /// Formats time as: "2:30 PM"
  String get toShortTime => DateFormat('h:mm a').format(this);

  /// Formats time as: "14:30"
  String get toMilitaryTime => DateFormat('HH:mm').format(this);

  /// Formats date and time as: "Jan 15, 2024 2:30 PM"
  String get toDateTimeShort => DateFormat('MMM d, y h:mm a').format(this);

  /// Formats date and time as: "January 15, 2024 at 2:30 PM"
  String get toDateTimeLong => DateFormat('MMMM d, y \'at\' h:mm a').format(this);

  /// Formats date and time as: "2024-01-15 14:30"
  String get toIsoStringLocal => DateFormat('yyyy-MM-dd HH:mm').format(this);

  /// Formats relative time (e.g., "2 hours ago", "3 days ago")
  String toRelativeTime({bool compact = false}) {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      return compact ? toShortDate : toMediumDate;
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Formats date with custom pattern
  String formatWithPattern(String pattern) {
    return DateFormat(pattern).format(this);
  }

  /// Formats date based on locale
  String formatWithLocale(String locale, {String? pattern}) {
    if (pattern != null) {
      return DateFormat(pattern, locale).format(this);
    }
    return DateFormat.yMMMd(locale).format(this);
  }

  /// Formats date as "Today", "Yesterday", or the date
  String get toRelativeDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    final difference = today.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7 && difference > 1) {
      return DateFormat('EEEE').format(this); // Day name
    } else {
      return toMediumDate;
    }
  }

  /// Formats date with ordinal numbers (e.g., "January 15th, 2024")
  String get toOrdinalDate {
    final day = this.day;
    final suffix = _getOrdinalSuffix(day);
    return DateFormat('MMMM d\'$suffix\', y').format(this);
  }

  /// Formats date as "Mon, Jan 15"
  String get toShortDateWithDay => DateFormat('EEE, MMM d').format(this);

  /// Formats date and time as "Today at 2:30 PM"
  String get toRelativeDateTime {
    final relativeDate = toRelativeDate;
    return '$relativeDate at $toShortTime';
  }

  /// Formats date as: "2024-01-15"
  String get toYearMonthDay => DateFormat('yyyy-MM-dd').format(this);

  /// Formats date as: "15/01/2024" (DD/MM/YYYY)
  String get toDayMonthYearShort => DateFormat('dd/MM/yyyy').format(this);

  /// Formats time as: "2:30:45 PM"
  String get toLongTime => DateFormat('h:mm:ss a').format(this);

  /// Formats date as "Q1 2024" (quarter and year)
  String get toQuarterYear {
    final quarter = ((month - 1) / 3).floor() + 1;
    return 'Q$quarter $year';
  }

  /// Formats date as "Jan" or "January"
  String get toMonthNameShort => DateFormat('MMM').format(this);
  String get toMonthNameLong => DateFormat('MMMM').format(this);

  /// Formats date as "Mon" or "Monday"
  String get toDayNameShort => DateFormat('EEE').format(this);
  String get toDayNameLong => DateFormat('EEEE').format(this);

  /// Formats date with timezone
  String get toDateTimeWithZone => DateFormat('MMM d, y h:mm a z').format(this);

  /// Formats date with time and timezone
  String get toFullDateTime => DateFormat('EEEE, MMMM d, y \'at\' h:mm:ss a').format(this);

  /// Formats date for file names (e.g., "2024-01-15_14-30-45")
  String get toFileName => DateFormat('yyyy-MM-dd_HH-mm-ss').format(this);

  /// Formats date with "st", "nd", "rd", "th" suffixes
  String get toFullOrdinalDate {
    final day = this.day;
    final suffix = _getOrdinalSuffix(day);
    return DateFormat('EEEE, MMMM d\'$suffix\', y').format(this);
  }

  /// Helper method to get ordinal suffix
  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
