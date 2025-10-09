import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // For prototype, navigate to OTP verification
      Navigator.of(context).pushReplacementNamed('/verify-otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter email';
                      final emailReg = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
                      if (!emailReg.hasMatch(v.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    obscureText: _obscure,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter password';
                      final s = v.trim();
                      if (s.length < 8)
                        return 'Password must be at least 8 characters';
                      if (!RegExp(r'[A-Z]').hasMatch(s))
                        return 'Include at least one uppercase letter';
                      if (!RegExp(r'[a-z]').hasMatch(s))
                        return 'Include at least one lowercase letter';
                      if (!RegExp(r'\d').hasMatch(s))
                        return 'Include at least one digit';
                      if (!RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(s))
                        return 'Include at least one special character';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Confirm password';
                      }
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Create account'),
                        ),
                      ),
                    ],
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
