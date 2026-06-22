import 'package:flutter/material.dart';

final List<Color> colorOptions = [
  Colors.greenAccent,
  Colors.blueAccent,
  Colors.redAccent,
  Colors.orangeAccent,
  Colors.purpleAccent,
  Colors.tealAccent,
  Colors.pinkAccent,
];

final List<Currency> currencies = [
  // Major world currencies
  /* NOTE Germany, France, Italy, Spain, Netherlands, Belgium, Portugal,
   * Greece, Austria and Ireland use EUR */
  Currency('USD', '\$', 'United States', '🇺🇸'),
  Currency('EUR', '€', 'European Union', '🇪🇺'),
  Currency('GBP', '£', 'United Kingdom', '🇬🇧'),
  Currency('JPY', '¥', 'Japan', '🇯🇵'),
  Currency('CNY', '¥', 'China', '🇨🇳'),
  Currency('INR', '₹', 'India', '🇮🇳'),
  Currency('BRL', 'R\$', 'Brazil', '🇧🇷'),
  Currency('RUB', '₽', 'Russia', '🇷🇺'),
  Currency('ZAR', 'R', 'South Africa', '🇿🇦'),

  // Americas
  Currency('CAD', 'CA\$', 'Canada', '🇨🇦'),
  Currency('MXN', 'Mex\$', 'Mexico', '🇲🇽'),
  Currency('ARS', 'AR\$', 'Argentina', '🇦🇷'),
  Currency('CLP', 'CL\$', 'Chile', '🇨🇱'),
  Currency('COP', 'CO\$', 'Colombia', '🇨🇴'),
  Currency('PEN', 'S/', 'Peru', '🇵🇪'),
  Currency('VES', 'Bs', 'Venezuela', '🇻🇪'),

  // Europe (non-Euro)
  Currency('CHF', 'CHF', 'Switzerland', '🇨🇭'),
  Currency('NOK', 'kr', 'Norway', '🇳🇴'),
  Currency('SEK', 'kr', 'Sweden', '🇸🇪'),
  Currency('DKK', 'kr', 'Denmark', '🇩🇰'),
  Currency('ISK', 'kr', 'Iceland', '🇮🇸'),
  Currency('PLN', 'zł', 'Poland', '🇵🇱'),
  Currency('CZK', 'Kč', 'Czech Republic', '🇨🇿'),
  Currency('HUF', 'Ft', 'Hungary', '🇭🇺'),
  Currency('RON', 'lei', 'Romania', '🇷🇴'),
  Currency('TRY', '₺', 'Turkey', '🇹🇷'),

  // Asia-Pacific
  Currency('AUD', 'AU\$', 'Australia', '🇦🇺'),
  Currency('NZD', 'NZ\$', 'New Zealand', '🇳🇿'),
  Currency('KRW', '₩', 'South Korea', '🇰🇷'),
  Currency('SGD', 'SG\$', 'Singapore', '🇸🇬'),
  Currency('MYR', 'RM', 'Malaysia', '🇲🇾'),
  Currency('THB', '฿', 'Thailand', '🇹🇭'),
  Currency('IDR', 'Rp', 'Indonesia', '🇮🇩'),
  Currency('PHP', '₱', 'Philippines', '🇵🇭'),
  Currency('VND', '₫', 'Vietnam', '🇻🇳'),
  Currency('PKR', 'Rs', 'Pakistan', '🇵🇰'),
  Currency('BDT', '৳', 'Bangladesh', '🇧🇩'),
  Currency('LKR', 'Rs', 'Sri Lanka', '🇱🇰'),

  // Middle East
  Currency('ILS', '₪', 'Israel', '🇮🇱'),
  Currency('SAR', 'SR', 'Saudi Arabia', '🇸🇦'),
  Currency('AED', 'د.إ', 'UAE', '🇦🇪'),
  Currency('KWD', 'KD', 'Kuwait', '🇰🇼'),
  Currency('QAR', 'QR', 'Qatar', '🇶🇦'),
  Currency('OMR', 'RO', 'Oman', '🇴🇲'),
  Currency('BHD', 'BD', 'Bahrain', '🇧🇭'),

  // Africa
  Currency('EGP', 'E£', 'Egypt', '🇪🇬'),
  Currency('NGN', '₦', 'Nigeria', '🇳🇬'),
  Currency('KES', 'KSh', 'Kenya', '🇰🇪'),
  Currency('TZS', 'TSh', 'Tanzania', '🇹🇿'),
  Currency('GHS', 'GH₵', 'Ghana', '🇬🇭'),
  Currency('MAD', 'DH', 'Morocco', '🇲🇦'),
  Currency('DZD', 'DA', 'Algeria', '🇩🇿'),
  Currency('TND', 'DT', 'Tunisia', '🇹🇳'),

  // Cryptocurrencies (why not?)
  Currency('BTC', '₿', 'Bitcoin', '🌐'),
  Currency('ETH', 'Ξ', 'Ethereum', '🌐'),
  Currency('USDT', '₮', 'Tether', '🌐'),
];

class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const Currency(this.code, this.symbol, this.name, this.flag);
}
