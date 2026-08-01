import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:to_do/data/expense_repository.dart';
import 'package:to_do/data/settings_repository.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/utils/currency_helper.dart';
import 'package:to_do/utils/transaction_type.dart';
import 'contact_detail_screen.dart';

import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';
import '../utils/app_transitions.dart';
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
  bool _isPermissionGranted = false;

  late final TextEditingController _searchController;
  late final bool _ownsSearchController;

  @override
  void initState() {
    super.initState();
    _ownsSearchController = widget.searchController == null;
    _searchController = widget.searchController ?? TextEditingController();
    _searchController.addListener(_filterContacts);
    unawaited(_checkPermissionAndLoad());
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    if (_ownsSearchController) _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionAndLoad() async {
    setState(() => _isLoading = true);
    try {
      final deviceContacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      if (!mounted) return;
      _isPermissionGranted = true;
      _combineAndSetContacts(deviceContacts);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPermissionGranted = false;
        _isLoading = false;
        _contacts = _getManualContactsAsContacts();
        _filteredContacts = _contacts;
      });
    }
  }

  List<Contact> _getManualContactsAsContacts() {
    final manual = widget.settingsRepository.manualContacts;
    return manual.map((m) {
      final name = m['name'] ?? 'Unknown';
      final phone = m['phone'] ?? '';
      return Contact(
        id: 'manual_$name',
        name: Name(first: name),
        displayName: name,
        phones: phone.isNotEmpty ? [Phone(number: phone)] : [],
      );
    }).toList();
  }

  Future<void> _requestPermissionAndLoad() async {
    setState(() => _isLoading = true);
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (!mounted) return;

      if (status == PermissionStatus.granted) {
        _isPermissionGranted = true;
        await _fetchContacts();
      } else if (status == PermissionStatus.permanentlyDenied) {
        setState(() {
          _isPermissionGranted = false;
          _isLoading = false;
          _contacts = _getManualContactsAsContacts();
          _filteredContacts = _contacts;
        });
        unawaited(FlutterContacts.permissions.openSettings());
      } else {
        setState(() {
          _isPermissionGranted = false;
          _isLoading = false;
          _contacts = _getManualContactsAsContacts();
          _filteredContacts = _contacts;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPermissionGranted = false;
        _isLoading = false;
        _contacts = _getManualContactsAsContacts();
        _filteredContacts = _contacts;
      });
    }
  }

  Future<void> _fetchContacts() async {
    try {
      final deviceContacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      _combineAndSetContacts(deviceContacts);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _contacts = _getManualContactsAsContacts();
        _filteredContacts = _contacts;
      });
    }
  }

  void _combineAndSetContacts(List<Contact> deviceContacts) {
    final manualContacts = _getManualContactsAsContacts();
    final existingNames = deviceContacts
        .map((c) => (c.displayName ?? '').toLowerCase())
        .toSet();
    final combined = List<Contact>.from(deviceContacts);
    for (final m in manualContacts) {
      if (!existingNames.contains((m.displayName ?? '').toLowerCase())) {
        combined.add(m);
      }
    }

    combined.sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));

    if (!mounted) return;
    setState(() {
      _contacts = combined;
      _filteredContacts = combined;
      _isLoading = false;
    });
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? _contacts
        : _contacts
            .where((contact) {
              final name = (contact.displayName ?? '').toLowerCase();
              final phones = contact.phones.map((p) => p.number).join(' ');
              return name.contains(query) || phones.contains(query);
            })
            .toList(growable: false);

    setState(() {
      _filteredContacts = filtered;
    });
  }

  Future<void> _showAddManualContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (optional)',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (added == true && nameController.text.trim().isNotEmpty) {
      await widget.settingsRepository.addManualContact(
        nameController.text.trim(),
        phoneController.text.trim(),
      );
      if (_isPermissionGranted) {
        await _fetchContacts();
      } else {
        setState(() {
          _contacts = _getManualContactsAsContacts();
          _filteredContacts = _contacts;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: GlassLoadingState(label: 'Loading contacts…'));
    }

    if (!_isPermissionGranted) {
      return _buildExplanationView();
    }

    return ListenableBuilder(
      listenable: widget.expenseRepository.listenable,
      builder: (context, _) {
        final allExpenses = widget.expenseRepository.getAll();
        final contactExpenses = allExpenses
            .where((e) => TransactionType.isContactType(e.type))
            .toList();

        double totalLent = 0;
        double totalBorrowed = 0;
        final Map<String, double> contactBalances = {};
        final Map<String, Expense> lastContactExpense = {};

        for (final expense in contactExpenses) {
          final cName = expense.contactName;
          if (cName == null || cName.trim().isEmpty) continue;

          if (expense.type == TransactionType.lent) {
            totalLent += expense.amount;
            contactBalances[cName] = (contactBalances[cName] ?? 0) + expense.amount;
          } else if (expense.type == TransactionType.borrowed) {
            totalBorrowed += expense.amount;
            contactBalances[cName] = (contactBalances[cName] ?? 0) - expense.amount;
          }
          lastContactExpense[cName] = expense;
        }

        final netLending = totalLent - totalBorrowed;
        final currencySymbol = widget.settingsRepository.currencySymbol;

        final recentContactNames = lastContactExpense.keys.toList();

        return ResponsiveContent(
          maxWidth: 760,
          child: CustomScrollView(
            slivers: [
              // 1. Financial Summary Card (Scrolls away)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: GlassCard(
                    radius: 20,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.people_alt_rounded,
                              size: 20,
                              color: AppColors.highlight,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MONEY WITH PEOPLE',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.primaryText.withValues(alpha: 0.64),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => unawaited(_showAddManualContactDialog()),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              tooltip: 'Add manual contact',
                              color: AppColors.highlight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Lent',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryText.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatCurrency(totalLent, currencySymbol),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.lendColorDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: AppColors.primaryText.withValues(alpha: 0.1),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Borrowed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryText.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatCurrency(totalBorrowed, currencySymbol),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.borrowedColorDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Net Balance:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText.withValues(alpha: 0.7),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${netLending >= 0 ? '+' : '-'}${formatCurrency(netLending.abs(), currencySymbol)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: netLending >= 0
                                      ? AppColors.lendColorDark
                                      : AppColors.borrowedColorDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Sticky Search Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchHeaderDelegate(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: FocusMotion(
                      builder: (context, focused, duration) => AnimatedContainer(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          color: AppColors.white,
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
                ),
              ),

              // 3. Recent Contacts (Scrolls away)
              if (recentContactNames.isNotEmpty && _searchController.text.isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: SectionLabel(
                      label: 'Recent Activity (${recentContactNames.length})',
                      icon: Icons.history_rounded,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 94,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: recentContactNames.length,
                      itemBuilder: (context, index) {
                        final name = recentContactNames[index];
                        final balance = contactBalances[name] ?? 0;
                        final lastEx = lastContactExpense[name];
                        final phone = lastEx?.phoneNumber;

                        return Container(
                          width: 140,
                          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                          child: Material(
                            color: AppColors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                unawaited(
                                  Navigator.push(
                                    context,
                                    AppTransitions.slideRight(
                                      page: ContactDetailScreen(
                                        contactName: name,
                                        phoneNumber: phone,
                                        expenseRepository: widget.expenseRepository,
                                        settingsRepository: widget.settingsRepository,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      balance == 0
                                          ? 'Settled up'
                                          : balance > 0
                                              ? 'Owes you ${formatCurrency(balance, currencySymbol)}'
                                              : 'You owe ${formatCurrency(balance.abs(), currencySymbol)}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: balance > 0
                                            ? AppColors.lendColorDark
                                            : balance < 0
                                                ? AppColors.borrowedColorDark
                                                : AppColors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // 4. All Contacts Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    children: [
                      SectionLabel(
                        label: 'All Contacts (${_filteredContacts.length})',
                        icon: Icons.people_alt_rounded,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => unawaited(_showAddManualContactDialog()),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Manual'),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. All Contacts List
              _filteredContacts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            _searchController.text.isNotEmpty
                                ? 'No contacts match "${_searchController.text}"'
                                : 'No contacts available. Tap + Manual to create one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primaryText.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final contact = _filteredContacts[index];
                          final phone = contact.phones.isNotEmpty
                              ? contact.phones.first.number
                              : 'No phone number';

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.5),
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
                                    AppTransitions.slideRight(
                                      page: ContactDetailScreen(
                                        contactName: contact.displayName ?? 'No Name',
                                        phoneNumber: phone != 'No phone number' ? phone : null,
                                        expenseRepository: widget.expenseRepository,
                                        settingsRepository: widget.settingsRepository,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: _filteredContacts.length,
                      ),
                    ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 88,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExplanationView() {
    return ResponsiveContent(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.highlight.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    size: 38,
                    color: AppColors.highlight,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Track Money With People',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Access your contacts to record money lent to or borrowed from friends and family. Your contact data remains 100% private on your device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: () => unawaited(_requestPermissionAndLoad()),
                    color: AppColors.highlight,
                    foregroundColor: AppColors.white,
                    child: const Text('Grant Access'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: () => unawaited(_showAddManualContactDialog()),
                    color: AppColors.white,
                    foregroundColor: AppColors.primaryText,
                    child: const Text('Add Contact Manually'),
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: child,
    );
  }

  @override
  double get maxExtent => 68.0;

  @override
  double get minExtent => 68.0;

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) => true;
}
