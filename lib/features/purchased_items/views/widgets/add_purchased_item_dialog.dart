import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';

class AddPurchasedItemSheet extends StatefulWidget {
  final Purchase purchase;
  final Group? group;

  const AddPurchasedItemSheet({
    super.key,
    required this.purchase,
    required this.group,
  });

  @override
  State<AddPurchasedItemSheet> createState() => _AddPurchasedItemSheetState();
}

enum ActiveField { quantity, price }

class _AddPurchasedItemSheetState extends State<AddPurchasedItemSheet> {
  String _name = '';
  String _priceStr = '';
  String _qtyStr = '1';
  String _discountStr = '0';
  bool _isWeight = false;

  ActiveField _activeField = ActiveField.price;

  List<Item> _allItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ItemsRepository>();
      final items = widget.group != null
          ? await repo.getItemsInGroup(widget.group!.id)
          : await repo.getItemsWithoutGroup();
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
      }
    }
  }

  void _loadLastPrice(int itemId) async {
    try {
      final repo = context.read<ItemsRepository>();
      final lastPrice = await repo.getLastPurchasedPrice(itemId);
      if (lastPrice != null && mounted) {
        setState(() => _priceStr = lastPrice.toString());
      }
    } catch (e) {
      // Silent fail for last price
    }
  }

  void _onKeypadPressed(String val) {
    setState(() {
      String current = _activeField == ActiveField.price ? _priceStr : _qtyStr;

      if (val == '<=') {
        if (current.isNotEmpty) {
          current = current.substring(0, current.length - 1);
        }
      } else if (val == 'C') {
        current = '';
      } else if (val == '=>') {
        _activeField = _activeField == ActiveField.price
            ? ActiveField.quantity
            : ActiveField.price;
        return;
      } else if (val == '.99') {
        if (current.isEmpty) {
          current = '0.99';
        } else if (!current.contains('.')) {
          current += '.99';
        } else {
          final parts = current.split('.');
          current = '${parts[0]}.99';
        }
      } else if (val == '.') {
        if (current.isEmpty) {
          current = '0.';
        } else if (!current.contains('.')) {
          current += val;
        }
      } else if (val == '-') {
        if (!current.startsWith('-')) {
          current = '-$current';
        } else {
          current = current.substring(1);
        }
      } else {
        if (current == '0') {
          current = val;
        } else {
          current += val;
        }
      }

      if (_activeField == ActiveField.price) {
        _priceStr = current;
      } else {
        _qtyStr = current;
      }
    });
  }

  void _showNameDialog() {
    final nameCtrl = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Name'),
        content: Autocomplete<Item>(
          initialValue: TextEditingValue(text: _name),
          displayStringForOption: (Item option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Item>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return _allItems.where(
              (Item option) => option.name.toLowerCase().contains(query),
            );
          },
          onSelected: (Item selection) {
            nameCtrl.text = selection.name;
            _loadLastPrice(selection.id);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            controller.addListener(() => nameCtrl.text = controller.text);
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search or enter new item',
              ),
              onSubmitted: (_) {
                setState(() => _name = nameCtrl.text);
                Navigator.pop(context);
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _name = nameCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog() {
    final discCtrl = TextEditingController(
      text: _discountStr == '0' ? '' : _discountStr,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discount'),
        content: TextField(
          controller: discCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter discount amount'),
          onSubmitted: (_) {
            setState(
              () => _discountStr = discCtrl.text.isEmpty ? '0' : discCtrl.text,
            );
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(
                () =>
                    _discountStr = discCtrl.text.isEmpty ? '0' : discCtrl.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    final name = _name.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item name')),
      );
      _showNameDialog();
      return;
    }

    final priceStr = _priceStr.trim();
    final qtyStr = _qtyStr.trim();
    if (priceStr.isEmpty || qtyStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in quantity and price')),
      );
      return;
    }

    final price = double.tryParse(priceStr) ?? 0.0;
    final qty = double.tryParse(qtyStr) ?? 1.0;
    final discount = double.tryParse(_discountStr.trim()) ?? 0.0;

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be greater than 0')),
      );
      return;
    }

    try {
      await context.read<PurchasedItemsRepository>().addPurchasedItem(
        name: name,
        price: price,
        qty: qty,
        discount: discount,
        isWeight: _isWeight,
        purchaseId: widget.purchase.id,
        group: widget.group,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding item: $e')));
      }
    }
  }

  Widget _buildFieldBox(
    String label,
    String value,
    ActiveField field, {
    Widget? customContent,
  }) {
    final isActive = _activeField == field;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeField = field),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? colorScheme.primary : colorScheme.outline,
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isActive ? colorScheme.primaryContainer : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              if (customContent != null)
                Expanded(child: customContent)
              else
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value.isEmpty ? '0' : value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildActionBtn({
    String? text,
    IconData? icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 56,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fg, size: 24),
                        if (text != null && text.isNotEmpty)
                          const SizedBox(width: 8),
                      ],
                      if (text != null && text.isNotEmpty)
                        Text(
                          text,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumBtn(String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: () => _onKeypadPressed(text),
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color redBg = isDark ? Colors.red.shade900 : Colors.red.shade100;
    Color redFg = isDark ? Colors.red.shade100 : Colors.red.shade900;
    Color greenBg = isDark ? Colors.green.shade900 : Colors.green.shade200;
    Color greenFg = isDark ? Colors.green.shade100 : Colors.green.shade900;
    Color blueBg = isDark ? Colors.blue.shade900 : Colors.blue.shade100;
    Color blueFg = isDark ? Colors.blue.shade100 : Colors.blue.shade900;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add an Item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  Text(
                    'Unit / kg',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isWeight,
                    onChanged: (val) {
                      setState(() {
                        _isWeight = val;
                        if (val) {
                          _qtyStr = '';
                          _activeField = ActiveField.quantity;
                        } else {
                          _qtyStr = '1';
                          _activeField = ActiveField.price;
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_isWeight)
                _buildFieldBox(
                  'Quantity (Weight)',
                  _qtyStr,
                  ActiveField.quantity,
                )
              else
                _buildFieldBox(
                  'Quantity',
                  _qtyStr,
                  ActiveField.quantity,
                  customContent: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAdjustBtn(Icons.remove, () {
                        double q = double.tryParse(_qtyStr) ?? 1;
                        if (q > 1) {
                          setState(() => _qtyStr = (q - 1).toInt().toString());
                        }
                      }),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _qtyStr.isEmpty ? '0' : _qtyStr,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildAdjustBtn(Icons.add, () {
                        double q = double.tryParse(_qtyStr) ?? 1;
                        setState(() => _qtyStr = (q + 1).toInt().toString());
                      }),
                    ],
                  ),
                ),
              _buildFieldBox(
                'Price (${_isWeight ? 'per kg' : 'per item'})',
                _priceStr,
                ActiveField.price,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionBtn(
                text: _isLoading
                    ? 'Loading...'
                    : (_name.isEmpty ? 'Name' : _name),
                bg: blueBg,
                fg: blueFg,
                onTap: _isLoading ? () {} : _showNameDialog,
              ),
              _buildActionBtn(
                text: 'Image',
                bg: blueBg,
                fg: blueFg,
                onTap: () {},
              ),
              _buildActionBtn(
                text: _discountStr == '0' || _discountStr.isEmpty
                    ? 'Discount'
                    : 'Disc: $_discountStr',
                bg: blueBg,
                fg: blueFg,
                onTap: _showDiscountDialog,
              ),
              _buildActionBtn(
                text: 'OK',
                bg: greenBg,
                fg: greenFg,
                onTap: _submit,
              ),
            ],
          ),
          Row(
            children: [
              _buildNumBtn('7'),
              _buildNumBtn('8'),
              _buildNumBtn('9'),
              _buildActionBtn(
                icon: Icons.backspace,
                bg: redBg,
                fg: redFg,
                onTap: () => _onKeypadPressed('<='),
              ),
            ],
          ),
          Row(
            children: [
              _buildNumBtn('4'),
              _buildNumBtn('5'),
              _buildNumBtn('6'),
              _buildActionBtn(
                text: 'C',
                bg: redBg,
                fg: redFg,
                onTap: () => _onKeypadPressed('C'),
              ),
            ],
          ),
          Row(
            children: [
              _buildNumBtn('1'),
              _buildNumBtn('2'),
              _buildNumBtn('3'),
              _buildActionBtn(
                text: '-',
                bg: redBg,
                fg: redFg,
                onTap: () => _onKeypadPressed('-'),
              ),
            ],
          ),
          Row(
            children: [
              _buildNumBtn('0'),
              _buildNumBtn('.'),
              _buildNumBtn('.99'),
              _buildActionBtn(
                icon: Icons.keyboard_tab,
                bg: greenBg,
                fg: greenFg,
                onTap: () => _onKeypadPressed('=>'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
