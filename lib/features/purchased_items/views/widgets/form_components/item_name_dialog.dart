import 'package:flutter/material.dart';
import 'package:shopping_assist/core/database/database.dart';

const double _kOptionsMaxHeight = 200.0;

String _itemDisplayName(Item option) => option.name;

class ItemNameDialog {
  static Future<void> show({
    required BuildContext context,
    required String currentName,
    required List<Item> allItems,
    required void Function(String name, int? itemId) onSave,
  }) async {
    final nameCtrl = TextEditingController(text: currentName);
    int? selectedItemId;

    try {
      final initialMatch = allItems.firstWhere(
        (item) => item.name.toLowerCase() == currentName.toLowerCase(),
      );
      selectedItemId = initialMatch.id;
    } catch (_) {
      selectedItemId = null;
    }

    await showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AlertDialog(
          title: Text('Item Name', style: Theme.of(context).textTheme.titleLarge),
          content: Autocomplete<Item>(
            initialValue: TextEditingValue(text: currentName),
            displayStringForOption: _itemDisplayName,
            optionsViewOpenDirection: OptionsViewOpenDirection.down,
            optionsViewBuilder: (context, onSelected, options) => _ItemOptionsView(
              options: options,
              onSelected: onSelected,
              displayStringForOption: _itemDisplayName,
            ),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Item>.empty();
              }
              final query = textEditingValue.text.toLowerCase();
              return allItems.where((Item option) => option.name.toLowerCase().contains(query));
            },
            onSelected: (Item selection) {
              nameCtrl.text = selection.name;
              selectedItemId = selection.id;
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              controller.addListener(() {
                nameCtrl.text = controller.text;
                if (selectedItemId != null) {
                  final matchingItem = allItems
                      .where((item) => item.id == selectedItemId)
                      .firstOrNull;
                  if (matchingItem == null ||
                      matchingItem.name.toLowerCase() != controller.text.toLowerCase()) {
                    selectedItemId = null;
                  }
                }
              });
              return TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search or enter new item',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  onSave(nameCtrl.text, selectedItemId);
                  Navigator.pop(context);
                },
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                onSave(nameCtrl.text, selectedItemId);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dropdown options list shown by [Autocomplete].
///
/// Mirrors the default Material options view, but wraps the list in a
/// [Scrollbar] with `thumbVisibility: true` so a scrollbar is shown whenever
/// the options overflow [_kOptionsMaxHeight] and hidden when they fit.
class _ItemOptionsView extends StatefulWidget {
  const _ItemOptionsView({
    required this.options,
    required this.onSelected,
    required this.displayStringForOption,
  });

  final Iterable<Item> options;
  final void Function(Item option) onSelected;
  final String Function(Item option) displayStringForOption;

  @override
  State<_ItemOptionsView> createState() => _ItemOptionsViewState();
}

class _ItemOptionsViewState extends State<_ItemOptionsView> {
  final ScrollController _scrollController = ScrollController();
  int _highlightedIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHighlightedOption(int highlightedIndex) {
    if (!mounted || highlightedIndex >= widget.options.length || !_scrollController.hasClients) {
      return;
    }
    final highlightedContext = GlobalObjectKey(
      widget.options.elementAt(highlightedIndex),
    ).currentContext;
    if (highlightedContext == null) {
      _scrollController.jumpTo(
        highlightedIndex == 0 ? 0.0 : _scrollController.position.maxScrollExtent,
      );
    } else {
      Scrollable.ensureVisible(highlightedContext, alignment: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int highlightedIndex = AutocompleteHighlightedOption.of(context);
    if (highlightedIndex != _highlightedIndex) {
      _highlightedIndex = highlightedIndex;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToHighlightedOption(highlightedIndex),
        debugLabel: 'ItemOptionsView.ensureVisible',
      );
    }

    return Material(
      elevation: 4.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _kOptionsMaxHeight),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: widget.options.length,
            itemBuilder: (context, index) {
              final Item option = widget.options.elementAt(index);
              return Semantics(
                button: true,
                child: InkWell(
                  key: GlobalObjectKey(option),
                  onTap: () => widget.onSelected(option),
                  child: Builder(
                    builder: (context) => Container(
                      color: highlightedIndex == index ? Theme.of(context).focusColor : null,
                      padding: const EdgeInsets.all(16.0),
                      child: Text(widget.displayStringForOption(option)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
