import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/features/settings/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(settings.themeMode.name.toUpperCase()),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_brightness),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (set) => settings.setThemeMode(set.first),
            ),
          ),

          ListTile(
            title: const Text('Theme Color'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 12,
                children: colorOptions.map((color) {
                  return GestureDetector(
                    onTap: () => settings.setSeedColor(color),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 20,
                        child: settings.seedColor == color
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.black,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(),
          const ListTile(
            title: Text(
              'Localization',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            title: const Text('Currency'),
            subtitle: Text(
              currencies
                  .firstWhere(
                    (c) => c.symbol == settings.currencySymbol,
                    orElse: () => currencies[0],
                  )
                  .name,
            ),
            trailing: DropdownButton<String>(
              value: settings.currencySymbol,
              items: currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency.symbol,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currency.flag),
                      const SizedBox(width: 8),
                      Text(currency.symbol),
                      const SizedBox(width: 4),
                      Text(
                        currency.code,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) settings.setCurrency(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const Currency(this.code, this.symbol, this.name, this.flag);
}
