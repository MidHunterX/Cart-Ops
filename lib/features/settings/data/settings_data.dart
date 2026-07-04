import 'package:flutter/material.dart';

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
  const Currency(this.code, this.symbol, this.name, this.flag);
}

final List<Currency> currencies = [
  // Major world currencies
  /* NOTE Germany, France, Italy, Spain, Netherlands, Belgium, Portugal,
   * Greece, Austria and Ireland use EUR */
  Currency('USD', '\$', 'United States Dollar', '🇺🇸'),
  Currency('EUR', '€', 'Euro', '🇪🇺'),
  Currency('GBP', '£', 'British Pound Sterling', '🇬🇧'),
  Currency('JPY', '¥', 'Japanese Yen', '🇯🇵'),
  Currency('CNY', '¥', 'Chinese Yuan Renminbi', '🇨🇳'),
  Currency('INR', '₹', 'Indian Rupee', '🇮🇳'),
  Currency('BRL', 'R\$', 'Brazilian Real', '🇧🇷'),
  Currency('RUB', '₽', 'Russian Ruble', '🇷🇺'),
  Currency('ZAR', 'R', 'South African Rand', '🇿🇦'),

  // Americas
  Currency('ARS', 'AR\$', 'Argentine Peso', '🇦🇷'),
  Currency('CAD', 'CA\$', 'Canadian Dollar', '🇨🇦'),
  Currency('CLP', 'CL\$', 'Chilean Peso', '🇨🇱'),
  Currency('COP', 'CO\$', 'Colombian Peso', '🇨🇴'),
  Currency('MXN', 'Mex\$', 'Mexican Peso', '🇲🇽'),
  Currency('PEN', 'S/', 'Peruvian Sol', '🇵🇪'),
  Currency('VES', 'Bs', 'Venezuelan Bolívar', '🇻🇪'),

  // Europe (non-Euro)
  Currency('CHF', 'CHF', 'Swiss Franc', '🇨🇭'),
  Currency('CZK', 'Kč', 'Czech Koruna', '🇨🇿'),
  Currency('DKK', 'kr', 'Danish Krone', '🇩🇰'),
  Currency('HUF', 'Ft', 'Hungarian Forint', '🇭🇺'),
  Currency('ISK', 'kr', 'Icelandic Króna', '🇮🇸'),
  Currency('NOK', 'kr', 'Norwegian Krone', '🇳🇴'),
  Currency('PLN', 'zł', 'Polish Złoty', '🇵🇱'),
  Currency('RON', 'lei', 'Romanian Leu', '🇷🇴'),
  Currency('SEK', 'kr', 'Swedish Krona', '🇸🇪'),
  Currency('TRY', '₺', 'Turkish Lira', '🇹🇷'),

  // Asia-Pacific
  Currency('AUD', 'AU\$', 'Australian Dollar', '🇦🇺'),
  Currency('BDT', '৳', 'Bangladeshi Taka', '🇧🇩'),
  Currency('IDR', 'Rp', 'Indonesian Rupiah', '🇮🇩'),
  Currency('KRW', '₩', 'South Korean Won', '🇰🇷'),
  Currency('LKR', 'Rs', 'Sri Lankan Rupee', '🇱🇰'),
  Currency('MYR', 'RM', 'Malaysian Ringgit', '🇲🇾'),
  Currency('NZD', 'NZ\$', 'New Zealand Dollar', '🇳🇿'),
  Currency('PHP', '₱', 'Philippine Peso', '🇵🇭'),
  Currency('PKR', 'Rs', 'Pakistani Rupee', '🇵🇰'),
  Currency('SGD', 'SG\$', 'Singapore Dollar', '🇸🇬'),
  Currency('THB', '฿', 'Thai Baht', '🇹🇭'),
  Currency('VND', '₫', 'Vietnamese Đồng', '🇻🇳'),

  // Middle East
  Currency('AED', 'د.إ', 'UAE Dirham', '🇦🇪'),
  Currency('BHD', 'BD', 'Bahraini Dinar', '🇧🇭'),
  Currency('ILS', '₪', 'Israeli New Shekel', '🇮🇱'),
  Currency('KWD', 'KD', 'Kuwaiti Dinar', '🇰🇼'),
  Currency('OMR', 'RO', 'Omani Rial', '🇴🇲'),
  Currency('QAR', 'QR', 'Qatari Riyal', '🇶🇦'),
  Currency('SAR', 'SR', 'Saudi Riyal', '🇸🇦'),

  // Africa
  Currency('DZD', 'DA', 'Algerian Dinar', '🇩🇿'),
  Currency('EGP', 'E£', 'Egyptian Pound', '🇪🇬'),
  Currency('GHS', 'GH₵', 'Ghanaian Cedi', '🇬🇭'),
  Currency('KES', 'KSh', 'Kenyan Shilling', '🇰🇪'),
  Currency('MAD', 'DH', 'Moroccan Dirham', '🇲🇦'),
  Currency('NGN', '₦', 'Nigerian Naira', '🇳🇬'),
  Currency('TND', 'DT', 'Tunisian Dinar', '🇹🇳'),
  Currency('TZS', 'TSh', 'Tanzanian Shilling', '🇹🇿'),

  // Cryptocurrencies (why not?)
  Currency('BTC', '₿', 'Bitcoin', '🌐'),
  Currency('ETH', 'Ξ', 'Ethereum', '🌐'),
  Currency('USDT', '₮', 'Tether', '🌐'),
];

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
