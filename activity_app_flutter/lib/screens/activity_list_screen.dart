import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/api_service.dart';
import 'activity_detail_screen.dart';
import 'my_registrations_screen.dart';
import 'login_register_screen.dart';
import 'add_edit_activity_screen.dart';

class ActivityListScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userRole;

  const ActivityListScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  late Future<List<Activity>> _activitiesFuture;

  bool get isAdmin => widget.userRole == 'admin';

  // Accent colors cycling through cards
  final List<Color> _accentColors = [
    const Color(0xFF00796B), // teal 700
    const Color(0xFF2E7D32), // green 800
    const Color(0xFF00897B), // teal 600
    const Color(0xFF388E3C), // green 700
  ];

  @override
  void initState() {
    super.initState();
    _activitiesFuture = ApiService.getActivities();
  }

  void _refresh() {
    setState(() {
      _activitiesFuture = ApiService.getActivities();
    });
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Activity'),
        content: Text(
            'Are you sure you want to delete "${activity.title}"?\nAll registrations will also be removed.'),
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
      await ApiService.deleteActivity(activity.activityId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Activity deleted'), backgroundColor: Colors.teal[700]),
      );
      _refresh();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F6),
      appBar: AppBar(
        toolbarHeight: 70,
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Campus Activities',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    'Hi, ${widget.userName} 👋',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: Colors.teal[700])),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
                      (route) => false,
                    ),
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AddEditActivityScreen()),
                );
                if (result == true) _refresh();
              },
              backgroundColor: Colors.teal[700],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
            )
          : null,
      body: Stack(
        children: [
          // Background corak motif — IgnorePointer so it never blocks touches
          IgnorePointer(
            child: SizedBox.expand(
              child: CustomPaint(painter: _BackgroundPatternPainter()),
            ),
          ),
          // Main content
          FutureBuilder<List<Activity>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.teal[700]));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final activities = snapshot.data ?? [];

          return RefreshIndicator(
            color: Colors.teal[700],
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              slivers: [
                // Curved header banner
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Background continuation from AppBar
                      Container(
                        height: 80,
                        color: Colors.teal[700],
                      ),
                      // Curved white card overlay
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F8F6),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Upcoming Activities',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${activities.length} event${activities.length == 1 ? '' : 's'} available',
                                    style: TextStyle(fontSize: 13, color: Colors.teal[600]),
                                  ),
                                ],
                              ),
                            ),
                            // Tappable calendar icon → My Registrations
                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MyRegistrationsScreen(userId: widget.userId),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.teal[200]!),
                                ),
                                child: Icon(Icons.calendar_month, color: Colors.teal[700], size: 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Activity cards
                activities.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.teal[200]),
                              const SizedBox(height: 12),
                              Text('No activities available',
                                  style: TextStyle(color: Colors.teal[400], fontSize: 16)),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final activity = activities[index];
                              final accentColor = _accentColors[index % _accentColors.length];
                              return _ActivityCard(
                                activity: activity,
                                accentColor: accentColor,
                                isAdmin: isAdmin,
                                onTap: () async {
                                  final result = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => ActivityDetailScreen(
                                        activity: activity,
                                        userId: widget.userId,
                                        userRole: widget.userRole,
                                      ),
                                    ),
                                  );
                                  if (result == true) _refresh();
                                },
                                onEdit: () async {
                                  final result = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => AddEditActivityScreen(activity: activity),
                                    ),
                                  );
                                  if (result == true) _refresh();
                                },
                                onDelete: () => _deleteActivity(activity),
                              );
                            },
                            childCount: activities.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final Color accentColor;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActivityCard({
    required this.activity,
    required this.accentColor,
    required this.isAdmin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left accent strip
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon container
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.event_rounded, color: accentColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              activity.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                          // Admin controls or chevron
                          if (isAdmin) ...[
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Colors.teal[600], size: 19),
                              tooltip: 'Edit',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: onEdit,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 19),
                              tooltip: 'Delete',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: onDelete,
                            ),
                          ] else
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Bottom info row
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: activity.location,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.people_outline,
                            label: '${activity.capacity} spots',
                            color: accentColor,
                          ),
                          const Spacer(),
                          // Date badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today, size: 11, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  activity.activityDate,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// Background corak motif painter
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Large soft circles for depth
    final circlePaint = Paint()
      ..color = Colors.teal.withOpacity(0.13)
      ..style = PaintingStyle.fill;

    final circlePaint2 = Paint()
      ..color = Colors.green.withOpacity(0.11)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 110, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.30), 90, circlePaint2);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.55), 80, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.75), 70, circlePaint2);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.90), 95, circlePaint);

    // Ring outlines for extra texture
    final ringPaint = Paint()
      ..color = Colors.teal.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;

    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 160, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.30), 140, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.55), 130, ringPaint);

    // Dot grid pattern
    final dotPaint = Paint()
      ..color = Colors.teal.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    const double dotSpacingX = 28;
    const double dotSpacingY = 28;
    const double dotRadius = 2.2;

    for (double x = dotSpacingX; x < size.width; x += dotSpacingX) {
      for (double y = dotSpacingY; y < size.height; y += dotSpacingY) {
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}