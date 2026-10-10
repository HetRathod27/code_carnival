import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/client.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../policies/policies_screen.dart';

class AccountScreen extends StatefulWidget {
  final ApiClient? client;
  final void Function(Locale)? onLocaleChanged;

  const AccountScreen({
    super.key,
    this.client,
    this.onLocaleChanged,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _successMessage;

  String _phone = '+919876543210';
  String _selectedCity = 'Gandhinagar';
  String _language = 'en';
  String _userId = '';
  int _priorityStrikes = 0;

  static const List<String> _supportedLanguages = ['en', 'gu', 'hi'];

  String _normalizeLanguage(String? lang) {
    if (lang == null || lang.isEmpty) return 'en';
    final clean = lang.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    if (_supportedLanguages.contains(clean)) {
      return clean;
    }
    return 'en';
  }

  @override
  void initState() {
    super.initState();
    _phoneController.text = _phone;
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ql_token') ?? '';
      _phone = prefs.getString('ql_phone') ?? '+919876543210';
      _phoneController.text = _phone;
      _selectedCity = prefs.getString('ql_selected_city') ?? 'Gandhinagar';
      _language = _normalizeLanguage(prefs.getString('ql_language'));
      final cachedName = prefs.getString('ql_user_name') ?? '';

      if (cachedName.isNotEmpty) {
        _nameController.text = cachedName;
      }

      if (token.isNotEmpty) {
        try {
          final profile = await _client.getProfile(token).timeout(const Duration(seconds: 4));
          if (profile.name != null && profile.name!.isNotEmpty) {
            _nameController.text = profile.name!;
            await prefs.setString('ql_user_name', profile.name!);
          }
          if (profile.phone != null && profile.phone!.isNotEmpty) {
            _phone = profile.phone!;
            _phoneController.text = _phone;
          }
          _userId = profile.id;
          _language = _normalizeLanguage(profile.language);
          _priorityStrikes = profile.priorityStrikes;
        } catch (_) {
          // Fall back gracefully to cached data if offline or timeout
          _userId = 'CITIZEN-${_phone.replaceAll(RegExp(r'\D'), '')}';
        }
      }
    } catch (e) {
      _error = 'Could not load details: $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleSaveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _error = 'Please enter your full name');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ql_token') ?? '';

      await prefs.setString('ql_user_name', newName);
      await prefs.setString('ql_language', _language);
      await prefs.setString('ql_selected_city', _selectedCity);

      if (token.isNotEmpty) {
        await _client.updateProfile(
          token: token,
          name: newName,
          language: _language,
        );
      }

      if (widget.onLocaleChanged != null) {
        widget.onLocaleChanged!(Locale(_language));
      }

      if (mounted) {
        setState(() {
          _saving = false;
          _successMessage = 'Profile details updated successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account details saved successfully!'),
            backgroundColor: CivicTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleCityChange() async {
    final cities = ['Gandhinagar', 'Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'];
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Your City'),
        children: cities.map((city) {
          final isSelected = city == _selectedCity;
          return SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(city),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? CivicTheme.primary : CivicTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  city,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? CivicTheme.primary : CivicTheme.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (chosen != null && chosen != _selectedCity) {
      setState(() => _selectedCity = chosen);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ql_selected_city', chosen);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of QueueLess?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CivicTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ql_token');
      if (mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop(true);
            } else {
              context.go('/offices');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Avatar Card
                        _buildProfileHeaderCard(),
                        const SizedBox(height: 20),

                        if (_successMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CivicTheme.successSoft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: CivicTheme.success, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _successMessage!,
                                    style: const TextStyle(
                                      color: CivicTheme.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CivicTheme.errorSoft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: CivicTheme.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: CivicTheme.error, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Section 1: Citizen Personal Details
                        _buildSectionTitle('Personal Details', Icons.person_outline),
                        const SizedBox(height: 8),
                        _buildPersonalDetailsCard(),
                        const SizedBox(height: 24),

                        // Section 2: Preferences & Location
                        _buildSectionTitle('App Preferences & Location', Icons.tune),
                        const SizedBox(height: 8),
                        _buildPreferencesCard(),
                        const SizedBox(height: 24),

                        // Section 3: Visit & Service History
                        _buildSectionTitle('Visit & Service History', Icons.history_edu),
                        const SizedBox(height: 8),
                        _buildHistoryQuickCard(),
                        const SizedBox(height: 24),

                        // Section 4: Civic Support & Service Status
                        _buildSectionTitle('Civic Support & Service Status', Icons.help_outline),
                        const SizedBox(height: 8),
                        _buildCivicSupportCard(),
                        const SizedBox(height: 32),

                        // Save Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: CivicTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _saving ? 'Saving Changes...' : 'Save & Update Details',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _saving ? null : _handleSaveProfile,
                        ),
                        const SizedBox(height: 16),

                        // Sign Out Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: CivicTheme.error,
                            side: const BorderSide(color: CivicTheme.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text('Sign Out / Switch Account', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _handleLogout,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: CivicTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CivicTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryQuickCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: CivicTheme.primarySoft, width: 1.5),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/history'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CivicTheme.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: CivicTheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Past Visits & Appointments',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CivicTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'View previous tokens, service milestones & feedback',
                      style: TextStyle(
                        fontSize: 12,
                        color: CivicTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CivicTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CivicTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CivicTheme.primary),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: CivicTheme.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final name = _nameController.text.trim();
    final displayName = name.isNotEmpty ? name : 'Citizen Beneficiary';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivicTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: CivicTheme.primarySoft,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: CivicTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CivicTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CivicTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CivicTheme.successSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✓ Verified Citizen Account',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CivicTheme.success,
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

  Widget _buildPersonalDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: CivicTheme.border),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Full Name (Editable)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name (Citizen / Beneficiary)',
                hintText: 'Enter your legal full name',
                prefixIcon: Icon(Icons.person, color: CivicTheme.primary),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Phone (Read-Only)
            TextField(
              controller: _phoneController,
              readOnly: true,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Registered Mobile Number (OTP Verified)',
                prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                suffixIcon: Tooltip(
                  message: 'Verified via OTP. Fixed to your civic token history.',
                  child: Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                ),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF9FAFB),
              ),
            ),
            if (_userId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Account Reference: $_userId',
                  style: const TextStyle(fontSize: 12, color: CivicTheme.textSecondary),
                ),
              ),
            ],
            if (_priorityStrikes > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CivicTheme.warningSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: CivicTheme.warning, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Priority Strikes: $_priorityStrikes / 3',
                      style: const TextStyle(fontSize: 12, color: CivicTheme.warning, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: CivicTheme.border),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Selected City
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: CivicTheme.primarySoft,
                  child: Icon(Icons.location_city, color: CivicTheme.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Registered Civic City', style: TextStyle(fontSize: 12, color: CivicTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        _selectedCity,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CivicTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Change'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: CivicTheme.primary,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: _handleCityChange,
                ),
              ],
            ),
            const Divider(height: 24),

            // Preferred Language
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: CivicTheme.accentSoft,
                  child: Icon(Icons.translate, color: CivicTheme.accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Interface & Notification Language', style: TextStyle(fontSize: 12, color: CivicTheme.textSecondary)),
                      DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: _normalizeLanguage(_language),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English (Default)')),
                          DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી (Gujarati)')),
                          DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _language = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCivicSupportCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: CivicTheme.border),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Row 1: Live Service Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: CivicTheme.successSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, color: CivicTheme.success, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Service Status',
                        style: TextStyle(fontSize: 12, color: CivicTheme.textSecondary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All Civic Centres Operational',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CivicTheme.success),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CivicTheme.successSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: CivicTheme.success, size: 8),
                      SizedBox(width: 5),
                      Text(
                        'Online',
                        style: TextStyle(color: CivicTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Row 2: Citizen Helpline
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: CivicTheme.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent, color: CivicTheme.primary, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Citizen Support Helpline',
                        style: TextStyle(fontSize: 12, color: CivicTheme.textSecondary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '1800-233-5500 (Toll-Free • 8 AM - 8 PM)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CivicTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Row 3: Privacy & Security Guarantee
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: CivicTheme.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: CivicTheme.accent, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Citizen Data Privacy',
                        style: TextStyle(fontSize: 12, color: CivicTheme.textSecondary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Zero Biometric Retention • Official Gujarat e-Gov',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CivicTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Row 4: Help & Rules Manual
            InkWell(
              onTap: () {
                try {
                  context.push('/policies');
                } catch (_) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: CivicTheme.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.help_outline_rounded, color: CivicTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.helpAndRulesAction ?? 'Help & Rules',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CivicTheme.primary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context)?.helpAndRulesSubtitle ?? 'Important information about appointments, arrival, cancellation and service.',
                            style: const TextStyle(fontSize: 12, color: CivicTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: CivicTheme.primary),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),

            // Row 5: App Version Footer
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('QueueLess Civic Portal', style: TextStyle(fontSize: 12, color: CivicTheme.textSecondary)),
                ),
                Text('v1.1.0 • Gujarat e-Gov', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CivicTheme.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
