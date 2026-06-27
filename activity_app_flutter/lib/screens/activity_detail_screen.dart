import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/api_service.dart';
import 'add_edit_activity_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  final int userId;
  final String userRole;
  final VoidCallback? onDeleted;
  final VoidCallback? onCompleted;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    required this.userId,
    required this.userRole,
    this.onDeleted,
    this.onCompleted,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _isRegistering = false;
  bool _isUpdatingStatus = false;
  bool _isNavigating = false;
  bool get isAdmin => widget.userRole == 'admin';

  String _getDaysRemaining() {
    final eventDate = DateTime.tryParse(widget.activity.activityDate);
    if (eventDate == null) return '';
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final event = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final diff = event.difference(today).inDays;
    if (diff == 0) return '🎉 Today!';
    if (diff == 1) return '⏰ Tomorrow';
    if (diff > 1) return '📅 In $diff days';
    if (diff == -1) return '✅ Yesterday';
    return '✅ ${diff.abs()} days ago';
  }

  Future<void> _register() async {
    setState(() => _isRegistering = true);
    try {
      await ApiService.registerForActivity(
        userId: widget.userId,
        activityId: widget.activity.activityId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Successfully registered!'), backgroundColor: Colors.teal[700]),
      );
      Navigator.of(context).pop(false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _markAsCompleted() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Completed'),
        content: Text(
            'Mark "${widget.activity.title}" as completed?\nIt will be removed from the Upcoming Activities list but users who registered can still see it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.teal[700])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mark Completed', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdatingStatus = true);
    try {
      await ApiService.updateActivityStatus(
        activityId: widget.activity.activityId,
        status: 'completed',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Activity marked as completed'),
          backgroundColor: Colors.green[700],
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      // onCompleted — removes from Upcoming Activities only
      widget.onCompleted?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Activity'),
        content: Text('Delete "${widget.activity.title}"? All registrations will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.teal[700])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.deleteActivity(widget.activity.activityId);
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      // onDeleted — removes from both Upcoming Activities and My Registrations
      widget.onDeleted?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Activity Details'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Activity',
                  onPressed: () async {
                    if (_isNavigating) return;
                    setState(() => _isNavigating = true);
                    try {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AddEditActivityScreen(activity: activity),
                        ),
                      );
                      if (result == true && mounted) Navigator.of(context).pop(true);
                    } finally {
                      if (mounted) setState(() => _isNavigating = false);
                    }
                  },
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[700]!, Colors.teal[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(icon: Icons.description_outlined, label: 'Description', value: activity.description, color: Colors.teal[700]!),
                    const Divider(height: 20),
                    _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: activity.location, color: Colors.green[700]!),
                    const Divider(height: 20),
                    _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date', value: activity.activityDate, color: Colors.teal[600]!),
                    const Divider(height: 20),
                    _DetailRow(icon: Icons.people_outline, label: 'Capacity', value: '${activity.capacity} students', color: Colors.teal[500]!),
                    const Divider(height: 20),
                    _DetailRow(icon: Icons.timer_outlined, label: 'Time Until Event', value: _getDaysRemaining(), color: Colors.teal[700]!),
                  ],
                ),
              ),
            ),

            const Spacer(),

            if (isAdmin) ...[
              ElevatedButton.icon(
                onPressed: (_isUpdatingStatus || widget.activity.status == 'completed')
                    ? null
                    : _markAsCompleted,
                icon: _isUpdatingStatus
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.task_alt_outlined),
                label: Text(
                  widget.activity.status == 'completed'
                      ? 'Already Completed'
                      : _isUpdatingStatus
                          ? 'Updating...'
                          : 'Mark as Completed',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: widget.activity.status == 'completed' ? Colors.grey[400] : Colors.green[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Activity'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 10),
            ],

            ElevatedButton.icon(
              onPressed: _isRegistering ? null : _register,
              icon: _isRegistering
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isRegistering ? 'Registering...' : 'Register for this Activity',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}