import 'package:flutter/material.dart';
import 'package:to_do/data/settings_repository.dart';
import 'package:to_do/utils/app_colors.dart';
import 'package:to_do/utils/app_design.dart';
import 'package:to_do/utils/app_motion.dart';
import 'package:to_do/utils/app_snackbar.dart';
import 'package:to_do/widget/glass_widgets.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final SettingsRepository settingsRepository;

  const ManageCategoriesScreen({
    super.key,
    this.settingsRepository = const SettingsRepository(),
  });

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final TextEditingController _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;

    await widget.settingsRepository.saveCategory(text);
    _addController.clear();

    if (mounted) {
      AppSnackbar.showSuccess(
        context: context,
        message: 'Category "$text" added',
      );
    }
  }

  Future<void> _editCategory(String oldName) async {
    final editController = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter new category name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      await widget.settingsRepository.editCategory(oldName, newName);
      if (mounted) {
        AppSnackbar.showSuccess(
          context: context,
          message: 'Category updated to "$newName"',
        );
      }
    }
  }

  Future<void> _deleteCategory(String categoryName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$categoryName"?'),
        content: const Text(
          'This category will be removed from your saved category options.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.snackbarError),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.settingsRepository.deleteCategory(categoryName);
      if (mounted) {
        AppSnackbar.showSuccess(
          context: context,
          message: 'Category "$categoryName" deleted',
        );
      }
    }
  }

  Future<void> _resetCategories() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Categories?'),
        content: const Text(
          'This will restore default categories (Food, Shopping, Salary, etc.).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.highlight, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.settingsRepository.resetCategories();
      if (mounted) {
        AppSnackbar.showSuccess(
          context: context,
          message: 'Categories reset to defaults',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'Reset to defaults',
            onPressed: _resetCategories,
          ),
        ],
      ),
      body: AppBackground(
        child: ResponsiveContent(
          child: ListenableBuilder(
            listenable: widget.settingsRepository.listenable,
            builder: (context, _) {
              final categories = widget.settingsRepository.categories;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  GlassCard(
                    radius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Category',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GlassInput(
                                controller: _addController,
                                fieldLabel: '',
                                hintText: 'e.g. Subscriptions, Fuel...',
                                prefixIcon: const Icon(Icons.category_outlined),
                              ),
                            ),
                            const SizedBox(width: 10),
                            PressScale(
                              child: GlassButton(
                                onPressed: _addCategory,
                                color: AppColors.highlight,
                                foregroundColor: AppColors.white,
                                radius: 14,
                                child: const Icon(Icons.add_rounded, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'AVAILABLE CATEGORIES (${categories.length})',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryText.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  GlassCard(
                    radius: 18,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final showDivider = index < categories.length - 1;

                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.highlight.withValues(alpha: 0.1),
                                child: Text(
                                  category.isNotEmpty ? category[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: AppColors.highlight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                category,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: AppColors.primaryText,
                                    ),
                                    tooltip: 'Edit Category',
                                    onPressed: () => _editCategory(category),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: AppColors.snackbarError,
                                    ),
                                    tooltip: 'Delete Category',
                                    onPressed: () => _deleteCategory(category),
                                  ),
                                ],
                              ),
                            ),
                            if (showDivider)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: AppColors.primaryText.withValues(alpha: 0.08),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
