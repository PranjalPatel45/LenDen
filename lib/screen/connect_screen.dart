import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:to_do/data/expense_repository.dart';
import 'package:to_do/data/settings_repository.dart';
import 'contact_detail_screen.dart';

import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';
import '../widget/glass_widgets.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({
    super.key,
    this.expenseRepository = const ExpenseRepository(),
    this.settingsRepository = const SettingsRepository(),
    this.searchController,
  });

  final ExpenseRepository expenseRepository;
  final SettingsRepository settingsRepository;
  final TextEditingController? searchController;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String _statusMessage = 'Requesting permissions...';

  late final TextEditingController _searchController;
  late final bool _ownsSearchController;

  @override
  void initState() {
    super.initState();
    _ownsSearchController = widget.searchController == null;
    _searchController = widget.searchController ?? TextEditingController();
    unawaited(_requestPermissionAndFetchContacts());
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    if (_ownsSearchController) _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionAndFetchContacts() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    if (!mounted) return;

    if (status == PermissionStatus.granted) {
      try {
        final contacts = await FlutterContacts.getAll(
          properties: {ContactProperty.phone},
        );
        if (!mounted) return;
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _statusMessage = 'Failed to load contacts.';
        });
      }
    } else if (status == PermissionStatus.denied) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Contacts permission denied.';
      });
    } else {
      setState(() {
        _isLoading = false;
        _statusMessage =
            'Contacts permission permanently denied. Please enable it from settings.';
      });
      unawaited(FlutterContacts.permissions.openSettings());
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    final filteredContacts = query.isEmpty
        ? _contacts
        : _contacts
              .where((contact) {
                final name = (contact.displayName ?? '').toLowerCase();
                return name.contains(query);
              })
              .toList(growable: false);

    setState(() {
      _filteredContacts = filteredContacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_contacts.isEmpty && !_isLoading) {
      return ResponsiveContent(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: GlassEmptyState(
              icon: Icons.contacts_rounded,
              title:
                  _statusMessage.contains('permission') ||
                      _statusMessage.contains('Failed')
                  ? 'Contacts unavailable'
                  : 'No contacts found',
              message:
                  _statusMessage.contains('permission') ||
                      _statusMessage.contains('Failed')
                  ? _statusMessage
                  : 'Your contacts will appear here.',
              action: SizedBox(
                width: 140,
                child: GlassButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _statusMessage = 'Requesting permissions...';
                    });
                    unawaited(_requestPermissionAndFetchContacts());
                  },
                  child: const Text('Retry'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: GlassLoadingState(label: 'Loading contacts…'));
    }

    return ResponsiveContent(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: FocusMotion(
              builder: (context, focused, duration) => AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  boxShadow: [
                    BoxShadow(
                      color: focused
                          ? AppColors.highlight.withValues(alpha: 0.12)
                          : AppColors.primaryText.withValues(alpha: 0.045),
                      blurRadius: focused ? 14 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search contacts',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SectionLabel(
                label: '${_filteredContacts.length} contacts',
                icon: Icons.people_alt_rounded,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                final phone = contact.phones.isNotEmpty
                    ? contact.phones.first.number
                    : 'No phone number';

                return EntranceMotion(
                  key: ValueKey('contact-${contact.id}-$index'),
                  order: index,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.46),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryText.withValues(alpha: 0.055),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.softLavender.withValues(alpha: 0.62),
                        ),
                        child: Text(
                          _getInitials(contact.displayName),
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.displayName ?? 'No Name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryText.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.grey,
                      ),
                      onTap: () {
                        unawaited(
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactDetailScreen(
                                contactName: contact.displayName ?? 'No Name',
                                phoneNumber: phone != 'No phone number'
                                    ? phone
                                    : null,
                                expenseRepository: widget.expenseRepository,
                                settingsRepository: widget.settingsRepository,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
