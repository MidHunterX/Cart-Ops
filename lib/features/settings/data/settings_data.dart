import 'package:flutter/material.dart';

class DominantHand {
  static const String right = 'Right';
  static const String left = 'Left';
  static const String center = 'Ambidextrous';
}

final List<Color> colorOptions = [
  Colors.green,
  Colors.blue,
  Colors.red,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
];

class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final String? countryCode;
  const Currency(this.code, this.symbol, this.name, this.flag, [this.countryCode]);
}

final List<Currency> currencies = [
  // Major world currencies
  /* NOTE Germany, France, Italy, Spain, Netherlands, Belgium, Portugal,
   * Greece, Austria and Ireland use EUR */
  Currency('USD', '\$', 'United States Dollar', '🇺🇸', 'US'),
  Currency('EUR', '€', 'Euro', '🇪🇺'), // multiple countries
  Currency('GBP', '£', 'British Pound Sterling', '🇬🇧', 'GB'),
  Currency('JPY', '¥', 'Japanese Yen', '🇯🇵', 'JP'),
  Currency('CNY', '¥', 'Chinese Yuan Renminbi', '🇨🇳', 'CN'),
  Currency('INR', '₹', 'Indian Rupee', '🇮🇳', 'IN'),
  Currency('BRL', 'R\$', 'Brazilian Real', '🇧🇷', 'BR'),
  Currency('RUB', '₽', 'Russian Ruble', '🇷🇺', 'RU'),
  Currency('ZAR', 'R', 'South African Rand', '🇿🇦', 'ZA'),

  // Americas
  Currency('ARS', 'AR\$', 'Argentine Peso', '🇦🇷', 'AR'),
  Currency('CAD', 'CA\$', 'Canadian Dollar', '🇨🇦', 'CA'),
  Currency('CLP', 'CL\$', 'Chilean Peso', '🇨🇱', 'CL'),
  Currency('COP', 'CO\$', 'Colombian Peso', '🇨🇴', 'CO'),
  Currency('MXN', 'Mex\$', 'Mexican Peso', '🇲🇽', 'MX'),
  Currency('PEN', 'S/', 'Peruvian Sol', '🇵🇪', 'PE'),
  Currency('VES', 'Bs', 'Venezuelan Bolívar', '🇻🇪', 'VE'),

  // Europe (non-Euro)
  Currency('CHF', 'CHF', 'Swiss Franc', '🇨🇭', 'CH'),
  Currency('CZK', 'Kč', 'Czech Koruna', '🇨🇿', 'CZ'),
  Currency('DKK', 'kr', 'Danish Krone', '🇩🇰', 'DK'),
  Currency('HUF', 'Ft', 'Hungarian Forint', '🇭🇺', 'HU'),
  Currency('ISK', 'kr', 'Icelandic Króna', '🇮🇸', 'IS'),
  Currency('NOK', 'kr', 'Norwegian Krone', '🇳🇴', 'NO'),
  Currency('PLN', 'zł', 'Polish Złoty', '🇵🇱', 'PL'),
  Currency('RON', 'lei', 'Romanian Leu', '🇷🇴', 'RO'),
  Currency('SEK', 'kr', 'Swedish Krona', '🇸🇪', 'SE'),
  Currency('TRY', '₺', 'Turkish Lira', '🇹🇷', 'TR'),

  // Asia-Pacific
  Currency('AUD', 'AU\$', 'Australian Dollar', '🇦🇺', 'AU'),
  Currency('BDT', '৳', 'Bangladeshi Taka', '🇧🇩', 'BD'),
  Currency('IDR', 'Rp', 'Indonesian Rupiah', '🇮🇩', 'ID'),
  Currency('KRW', '₩', 'South Korean Won', '🇰🇷', 'KR'),
  Currency('LKR', 'Rs', 'Sri Lankan Rupee', '🇱🇰', 'LK'),
  Currency('MYR', 'RM', 'Malaysian Ringgit', '🇲🇾', 'MY'),
  Currency('NZD', 'NZ\$', 'New Zealand Dollar', '🇳🇿', 'NZ'),
  Currency('PHP', '₱', 'Philippine Peso', '🇵🇭', 'PH'),
  Currency('PKR', 'Rs', 'Pakistani Rupee', '🇵🇰', 'PK'),
  Currency('SGD', 'SG\$', 'Singapore Dollar', '🇸🇬', 'SG'),
  Currency('THB', '฿', 'Thai Baht', '🇹🇭', 'TH'),
  Currency('VND', '₫', 'Vietnamese Đồng', '🇻🇳', 'VN'),

  // Middle East
  Currency('AED', 'د.إ', 'UAE Dirham', '🇦🇪', 'AE'),
  Currency('BHD', 'BD', 'Bahraini Dinar', '🇧🇭', 'BH'),
  Currency('ILS', '₪', 'Israeli New Shekel', '🇮🇱', 'IL'),
  Currency('KWD', 'KD', 'Kuwaiti Dinar', '🇰🇼', 'KW'),
  Currency('OMR', 'RO', 'Omani Rial', '🇴🇲', 'OM'),
  Currency('QAR', 'QR', 'Qatari Riyal', '🇶🇦', 'QA'),
  Currency('SAR', 'SR', 'Saudi Riyal', '🇸🇦', 'SA'),

  // Africa
  Currency('DZD', 'DA', 'Algerian Dinar', '🇩🇿', 'DZ'),
  Currency('EGP', 'E£', 'Egyptian Pound', '🇪🇬', 'EG'),
  Currency('GHS', 'GH₵', 'Ghanaian Cedi', '🇬🇭', 'GH'),
  Currency('KES', 'KSh', 'Kenyan Shilling', '🇰🇪', 'KE'),
  Currency('MAD', 'DH', 'Moroccan Dirham', '🇲🇦', 'MA'),
  Currency('NGN', '₦', 'Nigerian Naira', '🇳🇬', 'NG'),
  Currency('TND', 'DT', 'Tunisian Dinar', '🇹🇳', 'TN'),
  Currency('TZS', 'TSh', 'Tanzanian Shilling', '🇹🇿', 'TZ'),

  // Cryptocurrencies
  Currency('BTC', '₿', 'Bitcoin', '🌐'),
  Currency('ETH', 'Ξ', 'Ethereum', '🌐'),
  Currency('USDT', '₮', 'Tether', '🌐'),
];

Currency? getCurrencyByCountryCode(String countryCode) {
  const eurozoneCountries = {
    'AT', // Austria
    'BE', // Belgium
    'CY', // Cyprus
    'EE', // Estonia
    'FI', // Finland
    'FR', // France
    'DE', // Germany
    'GR', // Greece
    'IE', // Ireland
    'IT', // Italy
    'LV', // Latvia
    'LT', // Lithuania
    'LU', // Luxembourg
    'MT', // Malta
    'NL', // Netherlands
    'PT', // Portugal
    'SK', // Slovakia
    'SI', // Slovenia
    'ES', // Spain
    // Non-EU territories that use EUR:
    'AD', // Andorra
    'MC', // Monaco
    'ME', // Montenegro
    'SM', // San Marino
    'VA', // Vatican City
  };

  if (eurozoneCountries.contains(countryCode)) {
    return currencies.firstWhere((currency) => currency.code == 'EUR');
  }

  try {
    return currencies.firstWhere((currency) => currency.countryCode == countryCode);
  } catch (_) {
    return null;
  }
}

class WeightUnitOption {
  final String unit;
  final String system;
  final String name;
  const WeightUnitOption(this.unit, this.system, this.name);
}

const List<WeightUnitOption> weightUnitOptions = [
  WeightUnitOption('kg', 'Metric', 'Kilograms'),
  WeightUnitOption('lb', 'Imperial', 'Pounds'),
];
