import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/client.dart';
import '../../core/theme.dart';

class OfficesScreen extends StatefulWidget {
  final ApiClient? client;

  const OfficesScreen({super.key, this.client});

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();
  List<OfficeModel> _offices = [];
  TokenModel? _activeToken;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _client.fetchOffices();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ql_token');
      TokenModel? active;
      if (token != null) {
        try {
          active = await _client.getActiveToken(token);
        } catch (_) {
          active = null;
        }
      }
      if (mounted) {
        setState(() {
          _offices = list;
          _activeToken = active;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.officesTitle),
        actions: [
          if (_activeToken != null)
            IconButton(
              icon: const Icon(Icons.confirmation_number_outlined),
              tooltip: l10n.myToken,
              onPressed: () => context.push('/home'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retryAction,
            onPressed: _loadOffices,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: CivicTheme.error),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: CivicTheme.textPrimary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retryAction),
                            onPressed: _loadOffices,
                          ),
                        ],
                      ),
                    ),
                  )
                : _offices.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noOfficesFound,
                          style: const TextStyle(fontSize: 18, color: CivicTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOffices,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _offices.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_activeToken != null) ...[
                                    InkWell(
                                      onTap: () => context.push('/home'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: CivicTheme.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: CivicTheme.primary, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.confirmation_number, color: CivicTheme.primary, size: 28),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Active Appointment in Progress',
                                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: CivicTheme.primary),
                                                  ),
                                                  Text(
                                                    'Token: ${_activeToken!.displayCode} • Tap to view live ETA',
                                                    style: const TextStyle(fontSize: 13, color: CivicTheme.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_ios, size: 16, color: CivicTheme.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      l10n.selectOfficePrompt,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: CivicTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            final office = _offices[index - 1];
                            return _OfficeCard(
                              office: office,
                              onTap: () {
                                context.push('/offices/${office.id}/services');
                              },
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  final OfficeModel office;
  final VoidCallback onTap;

  const _OfficeCard({required this.office, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CivicTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CivicTheme.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0E5A8A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: CivicTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: CivicTheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        office.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: CivicTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: CivicTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              office.address,
                              style: const TextStyle(
                                fontSize: 15,
                                color: CivicTheme.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: CivicTheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: CivicTheme.border),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: CivicTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${l10n.officeHoursLabel}: ${office.openTime} – ${office.closeTime}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CivicTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
