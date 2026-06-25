import 'package:flutter/material.dart';
import 'package:shopping_assist/core/widgets/search_filter.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import '../../data/settings_data.dart';

class CurrencyPicker extends StatefulWidget {
  final SettingsProvider settings;

  const CurrencyPicker({super.key, required this.settings});

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<CurrencyPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Currency> get _filteredCurrencies {
    if (_searchQuery.isEmpty) return currencies;
    final query = _searchQuery.toLowerCase();
    return currencies
        .where(
          (c) =>
              c.code.toLowerCase().contains(query) ||
              c.name.toLowerCase().contains(query) ||
              c.symbol.contains(query),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SearchFilter(
            controller: _searchController,
            hintText: 'Search currency...',
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: () => setState(() => _searchQuery = ''),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredCurrencies.length,
            itemBuilder: (context, index) {
              final currency = _filteredCurrencies[index];
              return ListTile(
                leading: Text(
                  currency.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(currency.code),
                trailing: Text(
                  currency.symbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(currency.name),
                onTap: () {
                  widget.settings.setCurrency(currency.code);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
