import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/api_service.dart';

class AddEditActivityScreen extends StatefulWidget {
  // If activity is null, we're in Add mode. If provided, we're in Edit mode.
  final Activity? activity;

  const AddEditActivityScreen({super.key, this.activity});

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  bool get isEditMode => widget.activity != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    if (isEditMode) {
      final a = widget.activity!;
      _titleController.text = a.title;
      _descriptionController.text = a.description;
      _locationController.text = a.location;
      _capacityController.text = a.capacity.toString();
      _selectedDate = DateTime.tryParse(a.activityDate);
      if (_selectedDate != null) {
        _dateController.text = a.activityDate;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.teal[700]!,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dateStr = _dateController.text.trim();

    try {
      if (isEditMode) {
        await ApiService.updateActivity(
          activityId: widget.activity!.activityId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          activityDate: dateStr,
          capacity: int.parse(_capacityController.text.trim()),
        );
      } else {
        await ApiService.addActivity(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          activityDate: dateStr,
          capacity: int.parse(_capacityController.text.trim()),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Activity updated!' : 'Activity added!'),
          backgroundColor: Colors.teal[700],
        ),
      );
      Navigator.of(context).pop(true); // true = refresh the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.teal[700]) : null,
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Colors.teal[800]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Activity' : 'Add Activity'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _fieldDecoration('Activity Title', icon: Icons.title),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _fieldDecoration('Description', icon: Icons.description_outlined),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _locationController,
                decoration: _fieldDecoration('Location', icon: Icons.location_on_outlined),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
              ),
              const SizedBox(height: 14),

              // Date picker field
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: _fieldDecoration('Activity Date', icon: Icons.calendar_today_outlined).copyWith(
                      hintText: 'Tap to select date',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please select a date' : null,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('Capacity (number of students)', icon: Icons.people_outline),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Capacity is required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(isEditMode ? Icons.save_outlined : Icons.add_circle_outline),
                label: Text(
                  _isLoading
                      ? (isEditMode ? 'Saving...' : 'Adding...')
                      : (isEditMode ? 'Save Changes' : 'Add Activity'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}