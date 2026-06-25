import 'package:flutter/material.dart';
import './types.dart';

final List<Color> colorOptions = [
  Colors.green,
  Colors.blue,
  Colors.red,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
];

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
  Currency('CAD', 'CA\$', 'Canadian Dollar', '🇨🇦'),
  Currency('MXN', 'Mex\$', 'Mexican Peso', '🇲🇽'),
  Currency('ARS', 'AR\$', 'Argentine Peso', '🇦🇷'),
  Currency('CLP', 'CL\$', 'Chilean Peso', '🇨🇱'),
  Currency('COP', 'CO\$', 'Colombian Peso', '🇨🇴'),
  Currency('PEN', 'S/', 'Peruvian Sol', '🇵🇪'),
  Currency('VES', 'Bs', 'Venezuelan Bolívar', '🇻🇪'),

  // Europe (non-Euro)
  Currency('CHF', 'CHF', 'Swiss Franc', '🇨🇭'),
  Currency('NOK', 'kr', 'Norwegian Krone', '🇳🇴'),
  Currency('SEK', 'kr', 'Swedish Krona', '🇸🇪'),
  Currency('DKK', 'kr', 'Danish Krone', '🇩🇰'),
  Currency('ISK', 'kr', 'Icelandic Króna', '🇮🇸'),
  Currency('PLN', 'zł', 'Polish Złoty', '🇵🇱'),
  Currency('CZK', 'Kč', 'Czech Koruna', '🇨🇿'),
  Currency('HUF', 'Ft', 'Hungarian Forint', '🇭🇺'),
  Currency('RON', 'lei', 'Romanian Leu', '🇷🇴'),
  Currency('TRY', '₺', 'Turkish Lira', '🇹🇷'),

  // Asia-Pacific
  Currency('AUD', 'AU\$', 'Australian Dollar', '🇦🇺'),
  Currency('NZD', 'NZ\$', 'New Zealand Dollar', '🇳🇿'),
  Currency('KRW', '₩', 'South Korean Won', '🇰🇷'),
  Currency('SGD', 'SG\$', 'Singapore Dollar', '🇸🇬'),
  Currency('MYR', 'RM', 'Malaysian Ringgit', '🇲🇾'),
  Currency('THB', '฿', 'Thai Baht', '🇹🇭'),
  Currency('IDR', 'Rp', 'Indonesian Rupiah', '🇮🇩'),
  Currency('PHP', '₱', 'Philippine Peso', '🇵🇭'),
  Currency('VND', '₫', 'Vietnamese Đồng', '🇻🇳'),
  Currency('PKR', 'Rs', 'Pakistani Rupee', '🇵🇰'),
  Currency('BDT', '৳', 'Bangladeshi Taka', '🇧🇩'),
  Currency('LKR', 'Rs', 'Sri Lankan Rupee', '🇱🇰'),

  // Middle East
  Currency('ILS', '₪', 'Israeli New Shekel', '🇮🇱'),
  Currency('SAR', 'SR', 'Saudi Riyal', '🇸🇦'),
  Currency('AED', 'د.إ', 'UAE Dirham', '🇦🇪'),
  Currency('KWD', 'KD', 'Kuwaiti Dinar', '🇰🇼'),
  Currency('QAR', 'QR', 'Qatari Riyal', '🇶🇦'),
  Currency('OMR', 'RO', 'Omani Rial', '🇴🇲'),
  Currency('BHD', 'BD', 'Bahraini Dinar', '🇧🇭'),

  // Africa
  Currency('EGP', 'E£', 'Egyptian Pound', '🇪🇬'),
  Currency('NGN', '₦', 'Nigerian Naira', '🇳🇬'),
  Currency('KES', 'KSh', 'Kenyan Shilling', '🇰🇪'),
  Currency('TZS', 'TSh', 'Tanzanian Shilling', '🇹🇿'),
  Currency('GHS', 'GH₵', 'Ghanaian Cedi', '🇬🇭'),
  Currency('MAD', 'DH', 'Moroccan Dirham', '🇲🇦'),
  Currency('DZD', 'DA', 'Algerian Dinar', '🇩🇿'),
  Currency('TND', 'DT', 'Tunisian Dinar', '🇹🇳'),

  // Cryptocurrencies (why not?)
  Currency('BTC', '₿', 'Bitcoin', '🌐'),
  Currency('ETH', 'Ξ', 'Ethereum', '🌐'),
  Currency('USDT', '₮', 'Tether', '🌐'),
];
