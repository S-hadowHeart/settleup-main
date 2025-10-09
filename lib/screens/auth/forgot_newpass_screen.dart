import 'package:flutter/material.dart';

class ForgotPasswordNewPassScreen extends StatefulWidget {
  const ForgotPasswordNewPassScreen({super.key});

  @override
  State<ForgotPasswordNewPassScreen> createState() =>
      _ForgotPasswordNewPassScreenState();
}

class _ForgotPasswordNewPassScreenState
    extends State<ForgotPasswordNewPassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password reset')));
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set new password')),
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
                    controller: _passController,
                    decoration: InputDecoration(
                      labelText: 'New password',
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
                      if (v == null || v.isEmpty) return 'Confirm password';
                      if (v != _passController.text) {
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
                          onPressed: _save,
                          child: const Text('Save password'),
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
