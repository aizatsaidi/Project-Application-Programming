import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'activity_list_screen.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _showAdminCode = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> userData;

      if (_isLoginMode) {
        userData = await ApiService.loginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        userData = await ApiService.registerUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          adminCode: _adminCodeController.text.trim(),
        );
      }

      if (!mounted) return;

      final role = userData['role'] ?? 'student';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLoginMode
              ? 'Welcome back, ${userData['name']}!'
              : 'Account created as ${role == 'admin' ? 'Admin 🛡️' : 'Student'}!'),
          backgroundColor: Colors.teal[700],
        ),
      );

      if (_isLoginMode) {
        final userId = userData['user_id'] is int
            ? userData['user_id']
            : int.parse(userData['user_id'].toString());

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ActivityListScreen(
              userId: userId,
              userName: userData['name'] ?? '',
              userRole: role,
            ),
          ),
        );
      } else {
        setState(() {
          _isLoginMode = true;
          _passwordController.clear();
          _adminCodeController.clear();
          _showAdminCode = false;
        });
      }
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

  InputDecoration _fieldDecoration(String label, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.teal[600], size: 20) : null,
      suffixIcon: suffix,
      labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[400]!, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[300]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[800],
      body: Stack(
        children: [
          // Background corak
          IgnorePointer(
            child: SizedBox.expand(
              child: CustomPaint(painter: _BackgroundPatternPainter()),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top section — logo + title
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Student Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        'Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'UUM Campus Activities',
                        style: TextStyle(
                          color: Colors.teal[100],
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom white card
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab switcher
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _isLoginMode = true;
                                      _showAdminCode = false;
                                      _adminCodeController.clear();
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isLoginMode ? Colors.teal[700] : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Login',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _isLoginMode ? Colors.white : Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLoginMode = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isLoginMode ? Colors.teal[700] : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Register',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: !_isLoginMode ? Colors.white : Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name field (register only)
                          if (!_isLoginMode) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: _fieldDecoration('Full Name', icon: Icons.person_outline),
                              validator: (value) {
                                if (!_isLoginMode && (value == null || value.trim().isEmpty)) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _fieldDecoration('Email', icon: Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Email is required';
                              if (!value.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            decoration: _fieldDecoration(
                              'Password',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(
                                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Password is required';
                              if (!_isLoginMode && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Admin code (register only)
                          if (!_isLoginMode) ...[
                            Row(
                              children: [
                                Checkbox(
                                  value: _showAdminCode,
                                  activeColor: Colors.teal[700],
                                  onChanged: (val) {
                                    setState(() {
                                      _showAdminCode = val ?? false;
                                      if (!_showAdminCode) _adminCodeController.clear();
                                    });
                                  },
                                ),
                                Text(
                                  'I have an admin code',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                              ],
                            ),
                            if (_showAdminCode) ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _adminCodeController,
                                decoration: _fieldDecoration('Admin Code', icon: Icons.shield_outlined),
                                validator: (value) {
                                  if (_showAdminCode && (value == null || value.trim().isEmpty)) {
                                    return 'Enter the admin code or uncheck the box';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 14),
                          ],

                          const SizedBox(height: 8),

                          // Submit button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.teal[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    _isLoginMode ? 'Login' : 'Register',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Terms note
                          Text(
                            _isLoginMode
                                ? 'By logging in, you agree to UUM\'s terms of use.'
                                : 'By registering, you agree to UUM\'s terms of use.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Background corak
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.08), 120, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.10, size.height * 0.20), 80, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.35), 60, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.20, size.height * 0.42), 70, circlePaint);

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.08), 180, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.10, size.height * 0.20), 140, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.35), 110, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}