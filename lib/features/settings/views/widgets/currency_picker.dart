import 'package:flutter/material.dart';
import 'package:shopping_assist/core/widgets/search_filter.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import '../../data/settings_data.dart';

class CurrencyPicker extends StatefulWidget {
  const CurrencyPicker({super.key});

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
          padding: const EdgeInsets.only(left: 8, right: 16, bottom: 16),
          child: Row(
            children: [
              // IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              // const SizedBox(width: 8),
              Expanded(
                child: SearchFilter(
                  controller: _searchController,
                  hintText: 'Search currency...',
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onClear: () => setState(() => _searchQuery = ''),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredCurrencies.length + (_searchQuery.isEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (_searchQuery.isEmpty && index == 0) {
                final isDefault = context.settingsRead.isCurrencyDefault;
                return ListTile(
                  selected: isDefault,
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Icon(Icons.language, size: 24),
                  ),
                  title: const Text('Default (Device Locale)'),
                  onTap: () {
                    context.settingsRead.clearCurrency();
                    Navigator.pop(context);
                  },
                );
              }

              final currency = _filteredCurrencies[_searchQuery.isEmpty ? index - 1 : index];
              return ListTile(
                selected:
                    currency.code == context.currencyCode &&
                    !context.settingsRead.isCurrencyDefault,
                leading: Text(currency.flag, style: const TextStyle(fontSize: 24)),
                title: Text(currency.code),
                trailing: Text(
                  currency.symbol,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(currency.name),
                onTap: () {
                  context.settingsRead.setCurrency(currency.code);
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
