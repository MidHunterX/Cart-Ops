class KeypadLogic {
  static String calculateNewValue(String current, String val) {
    if (val == '<=') {
      if (current.isNotEmpty) {
        return current.substring(0, current.length - 1);
      }
      return current;
    } else if (val == 'C') {
      return '';
    } else if (val == '.99') {
      if (current.isEmpty) {
        return '0.99';
      } else if (!current.contains('.')) {
        return '$current.99';
      } else {
        final parts = current.split('.');
        return '${parts[0]}.99';
      }
    } else if (val == '.') {
      if (current.isEmpty) {
        return '0.';
      } else if (!current.contains('.')) {
        return '$current$val';
      }
      return current;
    } else if (val == '-') {
      if (!current.startsWith('-')) {
        return '-$current';
      } else {
        return current.substring(1);
      }
    } else {
      if (current == '0') {
        return val;
      } else {
        return current + val;
      }
    }
  }
}
