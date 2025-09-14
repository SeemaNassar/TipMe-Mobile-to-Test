// lib/utils/iban_validator.dart
class IbanValidator {
  static const String _saudiArabiaId = '08dded37-adf7-4e68-8e77-522b704e7f27';
  static const String _uaeId = '08dded37-ae14-449c-84e8-b204e47c4d4f';
  static const String _jordanId = '08dded37-adae-446d-8e8b-2b904cb9e397';

  static String? validateIban(String? iban, String? countryId) {
    if (iban == null || iban.trim().isEmpty) {
      return 'IBAN is required';
    }

    final cleanIban = iban.replaceAll(' ', '').toUpperCase();

    switch (countryId) {
      case _saudiArabiaId:
        return _validateSaudiIban(cleanIban);
      case _uaeId:
        return _validateUaeIban(cleanIban);
      case _jordanId:
        return _validateJordanIban(cleanIban);
      default:
        return _validateSaudiIban(cleanIban);
    }
  }

  /// Saudi Arabia IBAN validation (SA + 2 digits + 20 alphanumeric)
  static String? _validateSaudiIban(String iban) {
    if (!iban.startsWith('SA')) {
      return 'Saudi IBAN must start with SA';
    }
    if (iban.length != 24) {
      return 'Saudi IBAN must be 24 characters long';
    }
    if (!RegExp(r'^SA\d{2}[A-Z0-9]{20}$').hasMatch(iban)) {
      return 'Invalid Saudi IBAN format';
    }
    return _validateIbanChecksum(iban) ? null : 'Invalid Saudi IBAN checksum';
  }

  /// UAE IBAN validation (AE + 2 digits + 19 digits)
  static String? _validateUaeIban(String iban) {
    if (!iban.startsWith('AE')) {
      return 'UAE IBAN must start with AE';
    }
    if (iban.length != 23) {
      return 'UAE IBAN must be 23 characters long';
    }
    if (!RegExp(r'^AE\d{21}$').hasMatch(iban)) {
      return 'Invalid UAE IBAN format';
    }
    return _validateIbanChecksum(iban) ? null : 'Invalid UAE IBAN checksum';
  }

  /// Jordan IBAN validation (JO + 2 digits + 4 chars + 22 digits)
  static String? _validateJordanIban(String iban) {
    if (!iban.startsWith('JO')) {
      return 'Jordan IBAN must start with JO';
    }
    if (iban.length != 30) {
      return 'Jordan IBAN must be 30 characters long';
    }
    if (!RegExp(r'^JO\d{2}[A-Z]{4}\d{22}$').hasMatch(iban)) {
      return 'Invalid Jordan IBAN format';
    }
    return _validateIbanChecksum(iban) ? null : 'Invalid Jordan IBAN checksum';
  }

  /// IBAN checksum validation using mod-97 algorithm
  static bool _validateIbanChecksum(String iban) {
    final rearranged = iban.substring(4) + iban.substring(0, 4);

    final numericString = rearranged.split('').map((char) {
      if (RegExp(r'[A-Z]').hasMatch(char)) {
        return (char.codeUnitAt(0) - 'A'.codeUnitAt(0) + 10).toString();
      }
      return char;
    }).join('');

    return _bigIntMod97(numericString) == 1;
  }

  static int _bigIntMod97(String numericString) {
    int remainder = 0;
    for (int i = 0; i < numericString.length; i++) {
      remainder = (remainder * 10 + int.parse(numericString[i])) % 97;
    }
    return remainder;
  }

  static String getCountryName(String? countryId) {
    switch (countryId) {
      case _saudiArabiaId:
        return 'Saudi Arabia';
      case _uaeId:
        return 'United Arab Emirates';
      case _jordanId:
        return 'Jordan';
      default:
        return 'Unknown';
    }
  }

  static String formatIban(String iban) {
    final cleanIban = iban.replaceAll(' ', '');
    return cleanIban
        .replaceAllMapped(
          RegExp(r'.{4}'),
          (match) => '${match.group(0)} ',
        )
        .trim();
  }
}