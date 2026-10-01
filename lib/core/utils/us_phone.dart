/// US-only phone helpers (Shippo rejects anything it can't parse as a US number).
class UsPhone {
  UsPhone._();

  /// Returns the number as `+1XXXXXXXXXX`, or null if it isn't a valid US number.
  /// Accepts `(857) 230-2794`, `857-230-2794`, `18572302794`, `+1 857 230 2794`, etc.
  static String? normalize(String? input) {
    if (input == null) return null;
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('1')) {
      digits = digits.substring(1);
    }
    // NANP: area code and exchange code must start with 2-9.
    if (!RegExp(r'^[2-9]\d{2}[2-9]\d{6}$').hasMatch(digits)) return null;
    return '+1$digits';
  }

  static bool isValid(String? input) => normalize(input) != null;

  /// Form validator. Set [required] to false to allow an empty value.
  static String? validator(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Required' : null;
    }
    return isValid(value)
        ? null
        : 'Enter a valid US phone number (e.g. 857-230-2794)';
  }
}
