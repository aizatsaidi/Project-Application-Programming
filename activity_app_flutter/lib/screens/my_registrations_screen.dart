import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/api_service.dart';
import 'activity_detail_screen.dart';

class MyRegistrationsScreen extends StatefulWidget {
  final int userId;
  final String userRole;
  final void Function(int activityId)? onActivityDeleted;

  const MyRegistrationsScreen({
    super.key,
    required this.userId,
    required this.userRole,
    this.onActivityDeleted,
  });

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  List<Map<String, dynamic>> _registrations = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = ['All', 'registered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMyRegistrations(widget.userId);
      if (mounted) setState(() { _registrations = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _refresh() => _loadRegistrations();

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> registrations) {
    if (_selectedFilter == 'All') return registrations;
    return registrations.where((reg) {
      final status = (reg['registration_status'] ?? reg['status'] ?? '').toString();
      return status == _selectedFilter;
    }).toList();
  }

  Future<void> _cancel(int registrationId) async {
    try {
      await ApiService.cancelRegistration(registrationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Registration cancelled'), backgroundColor: Colors.teal[700]),
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

  void _confirmCancel(int registrationId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Registration'),
        content: Text('Are you sure you want to cancel your registration for "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('No', style: TextStyle(color: Colors.teal[700])),
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
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('My Registrations'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Stack(
            children: [
              Container(color: Colors.teal[700]),
              CustomPaint(
                painter: _AppBarPatternPainter(),
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          IgnorePointer(
            child: SizedBox.expand(
              child: CustomPaint(painter: _BackgroundPatternPainter()),
            ),
          ),
          Builder(builder: (context) {
            if (_isLoading) {
              return Center(child: CircularProgressIndicator(color: Colors.teal[700]));
            }

            final allRegistrations = _registrations;
            final registrations = _applyFilter(allRegistrations);

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list, size: 18, color: Colors.teal[700]),
                      const SizedBox(width: 8),
                      Text('Filter:', style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.w600),
                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.teal[700]),
                          items: _filterOptions.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(
                                option == 'All' ? 'All' : option[0].toUpperCase() + option.substring(1),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedFilter = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (allRegistrations.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 56, color: Colors.teal[200]),
                          const SizedBox(height: 12),
                          Text('No registered activities yet', style: TextStyle(color: Colors.teal[400])),
                        ],
                      ),
                    ),
                  )
                else if (registrations.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No "$_selectedFilter" registrations found.',
                        style: TextStyle(color: Colors.teal[400]),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      color: Colors.teal[700],
                      onRefresh: () async => _refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        itemCount: registrations.length,
                        itemBuilder: (context, index) {
                          final reg = registrations[index];
                          final regStatus = (reg['registration_status'] ?? reg['status'] ?? '').toString();
                          final activityStatus = (reg['activity_status'] ?? 'upcoming').toString();
                          final isCancelled = regStatus == 'cancelled';
                          final isActivityCompleted = activityStatus == 'completed';
                          final activityId = reg['activity_id'] is int
                              ? reg['activity_id'] as int
                              : int.tryParse(reg['activity_id'].toString()) ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isCancelled ? Colors.grey[100] : Colors.white,
                            elevation: isCancelled ? 1 : 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: isCancelled
                                  ? BorderSide(color: Colors.grey[300]!)
                                  : BorderSide(color: Colors.teal[100]!),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                final activity = Activity(
                                  activityId: activityId,
                                  title: (reg['title'] ?? '').toString(),
                                  description: (reg['description'] ?? '').toString(),
                                  location: (reg['location'] ?? '').toString(),
                                  activityDate: (reg['activity_date'] ?? '').toString(),
                                  capacity: reg['capacity'] is int
                                      ? reg['capacity']
                                      : int.tryParse(reg['capacity'].toString()) ?? 0,
                                  status: activityStatus,
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ActivityDetailScreen(
                                      activity: activity,
                                      userId: widget.userId,
                                      userRole: widget.userRole,
                                      onDeleted: () {
                                        // Remove from My Registrations
                                        setState(() {
                                          _registrations.removeWhere(
                                            (r) => r['activity_id'].toString() == activityId.toString(),
                                          );
                                        });
                                        // Also remove from Upcoming Activities
                                        widget.onActivityDeleted?.call(activityId);
                                      },
                                      onCompleted: () {
                                        // Update the activity_status to 'completed' in the local list
                                        setState(() {
                                          for (int i = 0; i < _registrations.length; i++) {
                                            if (_registrations[i]['activity_id'].toString() == activityId.toString()) {
                                              _registrations[i] = {
                                                ..._registrations[i],
                                                'activity_status': 'completed',
                                              };
                                              break;
                                            }
                                          }
                                        });
                                        // Notify Upcoming Activities to remove it
                                        widget.onActivityDeleted?.call(activityId);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCancelled ? Colors.grey[200] : Colors.teal[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isCancelled ? Icons.event_busy : Icons.event_available,
                                        color: isCancelled ? Colors.grey[400] : Colors.teal[700],
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reg['title'] ?? '',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isCancelled ? Colors.grey[500] : Colors.teal[900],
                                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text('📍 ${reg['location']}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          Text('📅 ${reg['activity_date']}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isCancelled ? Colors.grey[200] : Colors.teal[50],
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  isCancelled ? 'Cancelled' : 'Registered',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isCancelled ? Colors.grey[500] : Colors.teal[700],
                                                  ),
                                                ),
                                              ),
                                              if (isActivityCompleted) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[50],
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: Colors.green[300]!),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.task_alt, size: 11, color: Colors.green[700]),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        'Completed',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.green[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isCancelled && !isActivityCompleted)
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.cancel_outlined, size: 16),
                                        label: const Text('Cancel'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red[600],
                                          side: BorderSide(color: Colors.red[300]!),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        onPressed: () {
                                          final regId = reg['registration_id'] is int
                                              ? reg['registration_id']
                                              : int.parse(reg['registration_id'].toString());
                                          _confirmCancel(regId, reg['title'] ?? '');
                                        },
                                      )
                                    else if (isCancelled)
                                      const Icon(Icons.block, color: Colors.grey, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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
    final ringPaint = Paint()
      ..color = Colors.teal.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 160, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.30), 140, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.55), 130, ringPaint);
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

class _AppBarPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final accentPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.5), 55, accentPaint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 1.8), 65, accentPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * -0.5), 45, accentPaint);
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.5), 90, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * -0.5), 80, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}