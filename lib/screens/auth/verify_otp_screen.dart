import 'package:flutter/material.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verify() {
    final code = _codeController.text.trim();
    if (RegExp(r'^\d{4}$').hasMatch(code)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP verified')));
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 4-digit numeric OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter the 4-digit code sent to your email'),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'OTP code'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _verify,
                        child: const Text('Verify'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
