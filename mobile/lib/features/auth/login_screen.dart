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

  Future<void> _showServerConfigDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUrl = ApiClient.defaultBaseUrl;
    final controller = TextEditingController(text: currentUrl);
    String? testStatus;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings_ethernet, color: CivicTheme.primary),
              SizedBox(width: 8),
              Text('Server Connection', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select connection method or enter your backend server URL:',
                  style: TextStyle(fontSize: 13, color: CivicTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.usb, size: 16),
                      label: const Text('USB (localhost)'),
                      onPressed: () {
                        controller.text = 'http://localhost:8000';
                        setDialogState(() => testStatus = null);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi, size: 16),
                      label: const Text('Wi-Fi (10.152.45.97)'),
                      onPressed: () {
                        controller.text = 'http://10.152.45.97:8000';
                        setDialogState(() => testStatus = null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Backend Base URL',
                    hintText: 'http://10.152.45.97:8000',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                if (testStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      testStatus!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: testStatus!.startsWith('✓') ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.network_check, size: 16),
                  label: const Text('Test Connection'),
                  onPressed: () async {
                    setDialogState(() => testStatus = 'Testing...');
                    final ok = await ApiClient.pingServer(controller.text.trim());
                    setDialogState(() {
                      testStatus = ok ? '✓ Server reachable (/healthz: ok)' : '✗ Not reachable. Check IP or run adb reverse.';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  ApiClient.setBaseUrl(newUrl);
                  await prefs.setString('ql_server_url', ApiClient.defaultBaseUrl);
                  setState(() => _error = null);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signInTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            tooltip: 'Server Connection',
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _error!,
                                  style: const TextStyle(color: CivicTheme.error, fontSize: 13, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                  ),
                                  icon: const Icon(Icons.settings_ethernet, size: 16),
                                  label: const Text('Configure Server Connection / IP'),
                                  onPressed: _showServerConfigDialog,
                                ),
                              ],
                            ),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
