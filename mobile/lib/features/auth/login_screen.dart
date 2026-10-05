import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../api/client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '+919876543210');
  final TextEditingController _otpController = TextEditingController(text: '123456');
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  final ApiClient _client = ApiClient();

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _error = 'Please enter a valid mobile number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _otpSent = true;
      _loading = false;
    });
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Please enter 6-digit OTP');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // In development mode, fetch dev token for citizen
      final token = await _client.getDevToken(
        phone: phone,
        role: 'CITIZEN',
        name: 'Citizen User',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ql_token', token);
      await prefs.setString('ql_phone', phone);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QueueLess Sign In'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Enter Mobile Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: CivicTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Receive a 6-digit verification code to access your civic appointments.',
                style: TextStyle(fontSize: 16, color: CivicTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone_android, color: CivicTheme.primary),
                ),
                enabled: !_otpSent,
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-Digit OTP',
                    prefixIcon: Icon(Icons.lock_outline, color: CivicTheme.primary),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: CivicTheme.error, fontSize: 14),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _loading ? null : (_otpSent ? _handleVerifyOtp : _handleSendOtp),
                child: Text(
                  _loading
                      ? 'Please wait…'
                      : (_otpSent ? 'Verify OTP & Enter' : 'Get Verification Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
