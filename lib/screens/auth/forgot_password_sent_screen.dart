import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordSentScreen extends StatelessWidget {
  final String email;

  const ForgotPasswordSentScreen({super.key, required this.email});

  Future<void> _resendEmail(BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reset link sent again')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to resend link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset link sent')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read,
                  size: 60,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),

                const Text(
                  'A password reset link has been sent to:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => _resendEmail(context),
                  child: const Text('Resend link'),
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (_) => false);
                  },
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
