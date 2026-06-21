import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MyRegistrationsScreen extends StatefulWidget {
  final int userId;

  const MyRegistrationsScreen({super.key, required this.userId});

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  late Future<List<Map<String, dynamic>>> _registrationsFuture;

  @override
  void initState() {
    super.initState();
    _registrationsFuture = ApiService.getMyRegistrations(widget.userId);
  }

  void _refresh() {
    setState(() {
      _registrationsFuture = ApiService.getMyRegistrations(widget.userId);
    });
  }

  Future<void> _cancel(int registrationId) async {
    try {
      await ApiService.cancelRegistration(registrationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration cancelled'),
          backgroundColor: Colors.green,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmCancel(int registrationId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Registration'),
        content: Text('Are you sure you want to cancel your registration for "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancel(registrationId);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('My Registrations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _registrationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final registrations = snapshot.data ?? [];
          if (registrations.isEmpty) {
            return const Center(child: Text('You have no registered activities yet.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: registrations.length,
              itemBuilder: (context, index) {
                final reg = registrations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      reg['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📍 ${reg['location']}'),
                          Text('📅 ${reg['activity_date']}'),
                          Text('Status: ${reg['status']}'),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Cancel registration',
                      onPressed: () {
                        final regId = reg['registration_id'] is int
                            ? reg['registration_id']
                            : int.parse(reg['registration_id'].toString());
                        _confirmCancel(regId, reg['title'] ?? '');
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}