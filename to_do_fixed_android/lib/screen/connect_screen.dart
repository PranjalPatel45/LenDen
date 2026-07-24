import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];

  bool _isLoading = true;
  String _permissionMessage = 'Requesting permissions...';

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissionAndFetchContacts();

    _searchController.addListener(_filterContacts);
  }

  Future<void> _requestPermissionAndFetchContacts() async {
    final status = await Permission.contacts.request();

    if (status.isGranted) {
      try {
        final Iterable<Contact> contacts =
        await ContactsService.getContacts(
          withThumbnails: false,
        );

        setState(() {
          _contacts = contacts.toList();
          _filteredContacts = contacts.toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _permissionMessage = 'Failed to load contacts.';
        });
      }
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isLoading = false;
        _permissionMessage =
        'Contacts permission permanently denied. Please enable it from settings.';
      });

      openAppSettings();
    } else {
      setState(() {
        _isLoading = false;
        _permissionMessage =
        'Contacts permission denied.';
      });
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final name =
        (contact?.displayName ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Text(_permissionMessage),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Contacts',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredContacts.length,
            itemBuilder: (context, index) {
              final contact = _filteredContacts[index];

              final phone = contact.phones != null &&
                  contact.phones!.isNotEmpty
                  ? contact.phones!.first.value ??
                  'No phone number'
                  : 'No phone number';

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    contact.initials() ?? '?',
                  ),
                ),
                title: Text(
                  contact.displayName ?? 'No Name',
                ),
                subtitle: Text(phone),
              );
            },
          ),
        ),
      ],
    );
  }
}