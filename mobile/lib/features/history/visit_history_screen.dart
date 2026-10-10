import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/client.dart';
import '../../core/office_names.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

class VisitHistoryScreen extends StatefulWidget {
  final ApiClient? client;

  const VisitHistoryScreen({super.key, this.client});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();

  bool _loading = true;
  String? _error;
  List<TokenModel> _visits = [];
  String _selectedFilter = 'ALL'; // 'ALL', 'COMPLETED', 'ACTIVE', 'OTHER'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ql_token') ?? '';
      if (token.isEmpty) {
        if (mounted) context.go('/auth');
        return;
      }

      final list = await _client.getVisitHistory(token);
      if (mounted) {
        setState(() {
          _visits = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  List<TokenModel> get _filteredVisits {
    if (_selectedFilter == 'COMPLETED') {
      return _visits.where((v) => v.state == 'COMPLETED').toList();
    } else if (_selectedFilter == 'ACTIVE') {
      return _visits
          .where((v) => v.state == 'WAITING' || v.state == 'CALLED' || v.state == 'SERVING')
          .toList();
    } else if (_selectedFilter == 'OTHER') {
      return _visits
          .where((v) => v.state == 'CANCELLED' || v.state == 'NO_SHOW' || v.state == 'EXPIRED')
          .toList();
    }
    return _visits;
  }

  Color _getStatusColor(String state) {
    switch (state) {
      case 'COMPLETED':
        return CivicTheme.success;
      case 'SERVING':
      case 'CALLED':
        return CivicTheme.primary;
      case 'WAITING':
        return const Color(0xFF0284C7);
      case 'CANCELLED':
        return CivicTheme.error;
      case 'NO_SHOW':
      case 'EXPIRED':
        return const Color(0xFFD97706);
      default:
        return CivicTheme.textSecondary;
    }
  }

  Color _getStatusBgColor(String state) {
    switch (state) {
      case 'COMPLETED':
        return CivicTheme.successSoft;
      case 'SERVING':
      case 'CALLED':
        return CivicTheme.primarySoft;
      case 'WAITING':
        return const Color(0xFFE0F2FE);
      case 'CANCELLED':
        return const Color(0xFFFEE2E2);
      case 'NO_SHOW':
      case 'EXPIRED':
        return CivicTheme.warningSoft;
      default:
        return CivicTheme.canvas;
    }
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return isoString;
    }
  }

  String _formatDate(String? isoDate, String businessDate) {
    final raw = (isoDate != null && isoDate.isNotEmpty) ? isoDate : businessDate;
    if (raw.isEmpty) return '—';
    try {
      final parts = raw.split('T').first.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.visitHistoryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retryAction,
            onPressed: _loadHistory,
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
                          const Icon(Icons.error_outline, size: 48, color: CivicTheme.error),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: CivicTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retryAction),
                            onPressed: _loadHistory,
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Header Summary Banner
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: _buildHeaderCard(context, l10n),
                          ),
                        ),

                        // Filter Chips
                        SliverToBoxAdapter(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: '${l10n.filterAll} (${_visits.length})',
                                  value: 'ALL',
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label:
                                      '${l10n.filterCompleted} (${_visits.where((v) => v.state == "COMPLETED").length})',
                                  value: 'COMPLETED',
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label:
                                      '${l10n.filterUpcoming} (${_visits.where((v) => v.state == "WAITING" || v.state == "CALLED" || v.state == "SERVING").length})',
                                  value: 'ACTIVE',
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label:
                                      '${l10n.filterOther} (${_visits.where((v) => v.state == "CANCELLED" || v.state == "NO_SHOW" || v.state == "EXPIRED").length})',
                                  value: 'OTHER',
                                ),
                              ],
                            ),
                          ),
                        ),

                        // List of Visits or Empty State
                        _filteredVisits.isEmpty
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                                child: _buildEmptyState(context, l10n),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, idx) {
                                      final visit = _filteredVisits[idx];
                                      return _buildVisitCard(visit, currentLang, l10n);
                                    },
                                    childCount: _filteredVisits.length,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, AppLocalizations l10n) {
    final completedCount = _visits.where((v) => v.state == 'COMPLETED').length;

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
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: CivicTheme.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_edu, color: CivicTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.visitHistoryTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: CivicTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.visitHistorySubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CivicTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: CivicTheme.border),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatItem('Total Bookings', '${_visits.length}', Icons.receipt_long),
              Container(width: 1, height: 32, color: CivicTheme.border),
              _buildStatItem('Completed Services', '$completedCount', Icons.task_alt, isSuccess: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {bool isSuccess = false}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSuccess ? CivicTheme.success : CivicTheme.primary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isSuccess ? CivicTheme.success : CivicTheme.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: CivicTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: CivicTheme.primarySoft,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? CivicTheme.primary : CivicTheme.border,
        width: isSelected ? 1.5 : 1.0,
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? CivicTheme.primary : CivicTheme.textPrimary,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: CivicTheme.canvas,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off,
                size: 56,
                color: CivicTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noVisitsFound,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CivicTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noVisitsFoundSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: CivicTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text(l10n.bookSlot),
              onPressed: () {
                try {
                  context.go('/offices');
                } catch (_) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(TokenModel visit, String currentLang, AppLocalizations l10n) {
    final officeName = OfficeNames.getHumanOfficeName(visit.officeId, lang: currentLang);
    final serviceTitle = visit.serviceName != null && visit.serviceName!.isNotEmpty
        ? visit.serviceName!
        : 'Civic Service (${visit.serviceId})';
    final visitDate = _formatDate(visit.appointmentDate, visit.businessDate);
    final statusColor = _getStatusColor(visit.state);
    final statusBg = _getStatusBgColor(visit.state);
    final isLiveActive =
        visit.state == 'WAITING' || visit.state == 'CALLED' || visit.state == 'SERVING';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLiveActive ? CivicTheme.primary : CivicTheme.border,
            width: isLiveActive ? 1.5 : 1.0,
          ),
        ),
        elevation: 1,
        shadowColor: const Color(0x10000000),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
          initiallyExpanded: isLiveActive,
          tilePadding: const EdgeInsets.all(14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: CivicTheme.primarySoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              visit.displayCode,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: CivicTheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          title: Text(
            serviceTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CivicTheme.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: CivicTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    visitDate,
                    style: const TextStyle(fontSize: 12, color: CivicTheme.textSecondary),
                  ),
                  if (visit.appointmentSlot != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time, size: 12, color: CivicTheme.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        visit.appointmentSlot!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: CivicTheme.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      visit.state,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  if (visit.category == 'PRIORITY') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CivicTheme.accentSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRIORITY',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9E6000)),
                      ),
                    ),
                  ],
                  if (visit.childTokens.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CivicTheme.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${visit.childTokens.length} Group',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CivicTheme.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          children: [
            const Divider(color: CivicTheme.border),
            const SizedBox(height: 8),

            // Civic Office
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_balance_outlined, size: 16, color: CivicTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    officeName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CivicTheme.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Beneficiary / Applicant Name
            if (visit.beneficiaryName != null && visit.beneficiaryName!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: CivicTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Applicant: ${visit.beneficiaryName}',
                    style: const TextStyle(fontSize: 13, color: CivicTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Counter Served At
            if (visit.counterLabel != null && visit.counterLabel!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.desktop_windows_outlined, size: 16, color: CivicTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Service Desk: ${visit.counterLabel}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CivicTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),
            // Visit Journey Timeline
            _buildTimelineMilestones(visit),

            // Rating & Citizen Feedback (if available)
            if (visit.citizenRating != null || (visit.citizenFeedback != null && visit.citizenFeedback!.isNotEmpty)) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CivicTheme.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CivicTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFEAB308)),
                        const SizedBox(width: 6),
                        Text(
                          'Your Experience Rating: ${visit.citizenRating ?? 5}/5',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CivicTheme.textPrimary),
                        ),
                      ],
                    ),
                    if (visit.citizenFeedback != null && visit.citizenFeedback!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Feedback: "${visit.citizenFeedback}"',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: CivicTheme.textSecondary),
                      ),
                    ],
                    if (visit.citizenConfirmed == true) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          Icon(Icons.verified, size: 14, color: CivicTheme.success),
                          SizedBox(width: 4),
                          Text(
                            'Citizen Confirmed Done',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CivicTheme.success),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Accompanying Members
            if (visit.childTokens.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CivicTheme.primarySoft.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.group_outlined, size: 16, color: CivicTheme.primary),
                        SizedBox(width: 6),
                        Text(
                          'Accompanying Group Members',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CivicTheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...visit.childTokens.map((child) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${child.displayCode} - ${child.beneficiaryName ?? "Member"}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CivicTheme.textPrimary),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(child.state),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                child.state,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusColor(child.state),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Action for active token
            if (isLiveActive) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(l10n.viewActiveTokenAction),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  foregroundColor: CivicTheme.primary,
                  side: const BorderSide(color: CivicTheme.primary),
                ),
                onPressed: () {
                  try {
                    context.push('/home');
                  } catch (_) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildTimelineMilestones(TokenModel visit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CivicTheme.canvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildMilestoneRow(
            label: 'Booked / Scheduled',
            time: _formatTimestamp(visit.createdAt ?? visit.appointmentDate),
            icon: Icons.event_available,
            isDone: true,
          ),
          const SizedBox(height: 6),
          _buildMilestoneRow(
            label: 'Entrance Arrival Checked In',
            time: _formatTimestamp(visit.arrivedAt),
            icon: Icons.qr_code_scanner,
            isDone: visit.arrivedAt != null,
          ),
          const SizedBox(height: 6),
          _buildMilestoneRow(
            label: 'Called to Counter',
            time: _formatTimestamp(visit.calledAt),
            icon: Icons.volume_up_outlined,
            isDone: visit.calledAt != null,
          ),
          const SizedBox(height: 6),
          _buildMilestoneRow(
            label: 'Service Completed',
            time: _formatTimestamp(visit.completedAt),
            icon: Icons.check_circle_outline,
            isDone: visit.completedAt != null,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow({
    required String label,
    required String time,
    required IconData icon,
    required bool isDone,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDone ? CivicTheme.success : CivicTheme.textSecondary.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
              color: isDone ? CivicTheme.textPrimary : CivicTheme.textSecondary,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDone ? CivicTheme.textPrimary : CivicTheme.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
