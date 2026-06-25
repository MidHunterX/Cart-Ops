import 'package:flutter/material.dart';

class SearchFilter extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;

  const SearchFilter({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onClear,
    this.onChanged,
  });

  @override
  State<SearchFilter> createState() => _SearchFilterState();
}

class _SearchFilterState extends State<SearchFilter> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: widget.controller,
      hintText: widget.hintText,
      leading: const Icon(Icons.search),
      onChanged: (value) {
        setState(() {
          _query = value;
        });
        widget.onChanged?.call(value);
      },
      trailing: _query.isNotEmpty
          ? [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _query = '';
                    widget.controller.clear();
                  });
                  widget.onClear?.call();
                  widget.onChanged?.call('');
                },
              ),
            ]
          : null,
    );
  }
}
