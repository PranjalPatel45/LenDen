import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'glass_widgets.dart';

class CategoryField extends StatefulWidget {
  final String? selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;

  const CategoryField({
    super.key,
    this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends State<CategoryField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedCategory ?? '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant CategoryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory &&
        widget.selectedCategory != _controller.text) {
      _controller.text = widget.selectedCategory ?? '';
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onCategorySelected(_controller.text);
  }

  void _selectCategory(String cat) {
    _controller.text = cat;
    widget.onCategorySelected(cat);
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final matchingCategories = widget.categories
        .where((c) => c.toLowerCase().contains(query))
        .toList();

    final showCreateOption = query.isNotEmpty &&
        !widget.categories.any((c) => c.toLowerCase() == query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassInput(
          controller: _controller,
          labelText: 'Category (optional)',
          prefixIcon: const Icon(Icons.category_outlined),
          hintText: 'e.g. Food, Salary, Shopping...',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (showCreateOption)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: const Icon(Icons.add, size: 14, color: AppColors.white),
                    label: Text('Create "${_controller.text.trim()}"'),
                    backgroundColor: AppColors.highlight,
                    labelStyle: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onPressed: () {
                      _selectCategory(_controller.text.trim());
                    },
                  ),
                ),
              ...matchingCategories.map((cat) {
                final isSelected =
                    cat.toLowerCase() == _controller.text.trim().toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.highlight.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.highlight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.highlight : AppColors.primaryText,
                    ),
                    onSelected: (selected) {
                      _selectCategory(selected ? cat : '');
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
