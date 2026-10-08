import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../api/client.dart';
import '../../core/theme.dart';

class ServicesScreen extends StatefulWidget {
  final String officeId;
  final ApiClient? client;

  const ServicesScreen({
    super.key,
    required this.officeId,
    this.client,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();
  List<ServiceModel> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _client.fetchServices(widget.officeId);
      if (mounted) {
        setState(() {
          _services = list;
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
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.servicesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retryAction,
            onPressed: _loadServices,
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
                            onPressed: _loadServices,
                          ),
                        ],
                      ),
                    ),
                  )
                : _services.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noServicesFound,
                          style: const TextStyle(fontSize: 18, color: CivicTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadServices,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _services.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  l10n.selectServicePrompt,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: CivicTheme.textSecondary,
                                  ),
                                ),
                              );
                            }

                            final service = _services[index - 1];
                            return _ServiceCard(
                              service: service,
                              currentLang: currentLang,
                              onTap: () {
                                context.push('/book/${service.officeId}/${service.id}');
                              },
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final String currentLang;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.currentLang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = service.localizedName(currentLang);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: CivicTheme.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.code,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: CivicTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (service.priorityAllowed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: CivicTheme.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.priorityAllowedBadge,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9E6000),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: CivicTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: CivicTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${l10n.avgServiceDuration}: ~${service.priorAvgMinutes.round()} ${l10n.minutesUnit}',
                        style: const TextStyle(fontSize: 14, color: CivicTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (service.indicativeWaitMinutes != null && service.indicativeWaitMinutes! > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 16, color: CivicTheme.accent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${l10n.currentQueueWait}: ~${service.indicativeWaitMinutes} ${l10n.minutesUnit}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9E6000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (service.onlineAlternativeUrl != null && service.onlineAlternativeUrl!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CivicTheme.primarySoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language, size: 20, color: CivicTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.onlineAlternativeNotice,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CivicTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  label: Text(l10n.bookAppointmentAction),
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
