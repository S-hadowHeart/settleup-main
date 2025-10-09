import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _trySubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
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
                      prefixIcon: const Icon(Icons.lock),
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _trySubmit,
                          child: const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Navigate to forgot password flow
                      Navigator.of(context).pushNamed('/forgot-email');
                    },
                    child: const Text('Forgot password?'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to signup
                      Navigator.of(context).pushNamed('/signup');
                    },
                    child: const Text('Create account'),
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
