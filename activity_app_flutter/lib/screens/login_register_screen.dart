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

  InputDecoration _roundedInput(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.teal[700]) : null,
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: Colors.teal[800]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.teal[400]!, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[800],
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Login' : 'Register'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal[800]!,
              Colors.teal[500]!,
              Colors.teal[50]!,
              Colors.teal[50]!,
            ],
            stops: const [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Icon(Icons.school_rounded, size: 72, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    'Student Activity Registration',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UUM Campus Activities',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.teal[100], fontSize: 13),
                  ),
                  const SizedBox(height: 36),

                  // Name field -- Register mode only
                  if (!_isLoginMode) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: _roundedInput('Full Name', icon: Icons.person_outline),
                      validator: (value) {
                        if (!_isLoginMode && (value == null || value.trim().isEmpty)) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _roundedInput('Email', icon: Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email is required';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: _roundedInput('Password', icon: Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.teal[700],
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

                  // Admin code toggle -- Register mode only
                  if (!_isLoginMode) ...[
                    Row(
                      children: [
                        Checkbox(
                          value: _showAdminCode,
                          activeColor: Colors.teal[700],
                          checkColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              _showAdminCode = val ?? false;
                              if (!_showAdminCode) _adminCodeController.clear();
                            });
                          },
                        ),
                        Text(
                          'I have an admin code',
                          style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (_showAdminCode) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _adminCodeController,
                        decoration: _roundedInput('Admin Code', icon: Icons.shield_outlined),
                        validator: (value) {
                          // Only validate if checkbox is ticked
                          if (_showAdminCode && (value == null || value.trim().isEmpty)) {
                            return 'Enter the admin code or uncheck the box';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 14),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
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
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _isLoginMode = !_isLoginMode;
                              _showAdminCode = false;
                              _adminCodeController.clear();
                            }),
                    child: Text(
                      _isLoginMode
                          ? "Don't have an account? Register"
                          : 'Already have an account? Login',
                      style: TextStyle(
                        color: Colors.teal[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}