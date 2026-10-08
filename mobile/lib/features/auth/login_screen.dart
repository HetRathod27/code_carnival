import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
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

  Future<void> _handleSendOtp(AppLocalizations l10n) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _error = l10n.invalidPhoneError);
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

  Future<void> _handleVerifyOtp(AppLocalizations l10n) async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = l10n.invalidOtpError);
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
        // Always navigate to City Selection screen right after OTP verification
        context.go('/select-city');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signInTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.enterMobileNumber,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: CivicTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginSubtitle,
                style: const TextStyle(fontSize: 16, color: CivicTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone_android, color: CivicTheme.primary),
                ),
                enabled: !_otpSent,
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: l10n.otpLabel,
                    prefixIcon: const Icon(Icons.lock_outline, color: CivicTheme.primary),
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
                onPressed: _loading ? null : (_otpSent ? () => _handleVerifyOtp(l10n) : () => _handleSendOtp(l10n)),
                child: Text(
                  _loading
                      ? l10n.pleaseWait
                      : (_otpSent ? l10n.verifyOtpAction : l10n.sendOtpAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
