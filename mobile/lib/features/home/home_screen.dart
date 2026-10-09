import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/office_names.dart';
import '../../api/client.dart';

class HomeScreen extends StatefulWidget {
  final ApiClient? client;

  const HomeScreen({super.key, this.client});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();
  TokenModel? _activeToken;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  // Double verification & feedback state
  bool _serviceCompletedYes = true;
  String _reasonIfNot = '';
  int _ratingStars = 5;
  String _feedbackComments = '';
  bool _submittingConfirmation = false;

  @override
  void initState() {
    super.initState();
    _loadActiveToken();
    // Rule 8 & Spec Section 24: 20-second automatic polling fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        _loadActiveToken(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveToken({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('ql_token');
    if (token == null) {
      if (mounted) context.go('/auth');
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final active = await _client.getActiveToken(token);
      if (mounted) {
        if (active == null && !silent) {
          try {
            context.go('/select-city');
            return;
          } catch (_) {
            // Fallback for tests running outside GoRouter
          }
        }
        setState(() {
          _activeToken = active;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleCheckIn() async {
    final token = _activeToken;
    if (token == null) return;

    final l10n = AppLocalizations.of(context)!;

    final qrPayload = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: CivicTheme.primary, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.checkInQr,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.qrCodeInstruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: CivicTheme.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 16),
                // ACTUAL QR CODE TO SHOW TO DEPT OFFICER
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CivicTheme.border, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140E5A8A),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: 'TOKEN:${token.id}:${token.displayCode}',
                    version: QrVersions.auto,
                    size: 190.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0E5A8A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // BACKUP CODE GIVEN TO EMPLOYEE IF QR HAS ISSUE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: CivicTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.manualVerificationCodePrompt.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: CivicTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        token.displayCode,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: CivicTheme.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.qrFallbackOfficerNotice,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CivicTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.cancelAction),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(
              'TOKEN:${token.id}:${token.displayCode}',
            ),
            child: Text(l10n.verifyArrivalAction),
          ),
        ],
      ),
    );

    if (qrPayload == null || qrPayload.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('ql_token') ?? '';
      final updated = await _client.checkIn(
        token: authToken,
        tokenId: token.id,
        qrPayload: qrPayload,
      );
      if (mounted) {
        setState(() => _activeToken = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.presenceVerified),
            backgroundColor: CivicTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: CivicTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleOnMyWay() async {
    final token = _activeToken;
    if (token == null) return;
    final l10n = AppLocalizations.of(context)!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('ql_token') ?? '';
      final updated = await _client.onMyWay(token: authToken, tokenId: token.id);
      if (mounted) {
        setState(() => _activeToken = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.onMyWaySuccess),
            backgroundColor: CivicTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: CivicTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleCancel() async {
    final token = _activeToken;
    if (token == null) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: CivicTheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.cancelAppointment)),
          ],
        ),
        content: Text(l10n.confirmCancelPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.keepAppointmentAction),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CivicTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.yesCancelAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('ql_token') ?? '';
      await _client.cancelToken(token: authToken, tokenId: token.id);
      if (mounted) {
        setState(() => _activeToken = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cancelSuccessMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: CivicTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleConfirmCompletion(TokenModel token) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('ql_token') ?? '';
    setState(() => _submittingConfirmation = true);

    try {
      await _client.confirmCompletion(
        token: authToken,
        tokenId: token.id,
        serviceCompleted: _serviceCompletedYes,
        reasonIfNot: _serviceCompletedYes ? null : _reasonIfNot,
        rating: _ratingStars,
        feedbackText: _feedbackComments.isNotEmpty ? _feedbackComments : null,
      );

      if (mounted) {
        setState(() {
          _activeToken = null;
          _submittingConfirmation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification and feedback submitted successfully!'),
            backgroundColor: CivicTheme.success,
          ),
        );

        // Directly redirect to list of civic centres available in the city
        try {
          context.go('/offices');
        } catch (_) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submittingConfirmation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: CivicTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ql_token');
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retryAction,
            onPressed: () => _loadActiveToken(),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'My Account',
            onPressed: () async {
              await context.push('/account');
              _loadActiveToken();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOutTooltip,
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: CivicTheme.error),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retryAction),
                            onPressed: () => _loadActiveToken(),
                          ),
                        ],
                      ),
                    )
                  : _activeToken != null
                      ? RefreshIndicator(
                          onRefresh: () => _loadActiveToken(),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: _buildActiveTokenCard(_activeToken!, l10n),
                          ),
                        )
                      : _buildNoActiveTokenView(l10n),
        ),
      ),
    );
  }

  Widget _buildActiveTokenCard(TokenModel token, AppLocalizations l10n) {
    if (token.state == 'COMPLETED') {
      return _buildCompletionVerificationView(token, l10n);
    }

    final isArrived = token.arrivedAt != null;
    final onMyWayClaimed = token.onMyWayAt != null;
    final currentLang = Localizations.localeOf(context).languageCode;

    // Check if appointment is for a future date (Requirement 3: Differentiate future appointment)
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final isFutureAppointment =
        token.businessDate.isNotEmpty && token.businessDate.compareTo(todayStr) > 0;

    // Check for office delay / paused queue (Requirement 10: Server/Office Delay notice)
    final hasOfficeDelay = token.lastEtaReason != null &&
        (token.lastEtaReason!.toUpperCase().contains('DELAY') ||
            token.lastEtaReason!.toUpperCase().contains('PAUSED') ||
            token.lastEtaReason!.toUpperCase().contains('COUNTER_DOWN') ||
            token.lastEtaReason!.toUpperCase().contains('RUSH'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Office Service Delay Alert Banner (Requirement 10)
        if (hasOfficeDelay) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CivicTheme.warningSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CivicTheme.warning, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.officeDelayAlert,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Called Banner
        if (token.state == 'CALLED') ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CivicTheme.accentSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CivicTheme.accent, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.ring_volume, color: Color(0xFFB45309), size: 26),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'YOUR TURN HAS ARRIVED!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                if (token.counterLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Proceed to: ${token.counterLabel}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CivicTheme.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CivicTheme.border),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: token.verificationQr ?? 'VERIFY:${token.id}:${token.verificationSecret ?? ""}',
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        token.displayCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: CivicTheme.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (token.verificationSecret != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: CivicTheme.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: CivicTheme.primary),
                          ),
                          child: Column(
                            children: [
                              Text(
                                l10n.counterVerificationSecretLabel.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: CivicTheme.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                token.verificationSecret!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: CivicTheme.primary,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        l10n.showVerificationCodeToOfficer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: CivicTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Main Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CivicTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CivicTheme.primary, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x110E5A8A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                isFutureAppointment
                    ? l10n.appointmentConfirmedCardTitle.toUpperCase()
                    : l10n.myToken.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: CivicTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                token.displayCode,
                key: const Key('active_token_code'),
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: CivicTheme.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFutureAppointment ? CivicTheme.successSoft : CivicTheme.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFutureAppointment ? l10n.appointmentConfirmedCardTitle : token.state,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isFutureAppointment ? CivicTheme.success : CivicTheme.primary,
                      ),
                    ),
                  ),
                  if (token.category == 'PRIORITY') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: CivicTheme.accentSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.priorityBadge,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9E6000),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Civic Centre Human Name (Never show technical IDs like ward-central-01)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CivicTheme.primarySoft.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, color: CivicTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        OfficeNames.getHumanOfficeName(token.officeId, lang: currentLang),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CivicTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Future Appointment View vs Active Waiting View (Requirement 3)
              if (isFutureAppointment) ...[
                // Notice: Not yet appointment time
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CivicTheme.canvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CivicTheme.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.event, color: CivicTheme.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.appointmentFutureNotice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CivicTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: CivicTheme.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.appointmentScheduledFor,
                        style: const TextStyle(fontSize: 15, color: CivicTheme.textSecondary),
                      ),
                    ),
                    Text(
                      token.businessDate,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ] else ...[
                // Appointment Day / Active Waiting View
                // Arrival Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isArrived ? CivicTheme.successSoft : CivicTheme.canvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isArrived ? CivicTheme.success : CivicTheme.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isArrived ? Icons.verified : Icons.location_on_outlined,
                        size: 18,
                        color: isArrived ? CivicTheme.success : CivicTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isArrived ? l10n.presenceVerified : l10n.notCheckedInStatus,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isArrived ? CivicTheme.success : CivicTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (token.verificationSecret != null && token.state != 'CALLED') ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: CivicTheme.primarySoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.key, size: 18, color: CivicTheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.counterVerificationSecretLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CivicTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          token.verificationSecret!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: CivicTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(color: CivicTheme.border),
                const SizedBox(height: 12),

                // Queue metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(l10n.waitingAhead, style: const TextStyle(fontSize: 16))),
                    Text(
                      '${token.waitingAhead}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (token.nowServing != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(l10n.nowServingAt, style: const TextStyle(fontSize: 16))),
                      Flexible(
                        child: Text(
                          '${token.nowServing}${token.counterLabel != null ? " (${token.counterLabel})" : ""}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: CivicTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(l10n.estimatedTurn, style: const TextStyle(fontSize: 16))),
                    Text(
                      token.lastEtaMinutes != null
                          ? '~${token.lastEtaMinutes!.round()} ${l10n.minutesUnit}'
                          : l10n.calculatingEta,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                // ETA Range (p50 / low / high)
                if (token.etaLow != null && token.etaHigh != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.etaRangePrefix,
                          style: const TextStyle(fontSize: 14, color: CivicTheme.textSecondary),
                        ),
                      ),
                      Text(
                        '${token.etaLow!.round()} – ${token.etaHigh!.round()} ${l10n.minutesUnit}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CivicTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                // Last ETA Reason
                if (token.lastEtaReason != null && token.lastEtaReason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CivicTheme.primarySoft.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: CivicTheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            token.lastEtaReason!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CivicTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (token.childTokens.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(color: CivicTheme.border),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CivicTheme.primarySoft.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined, size: 16, color: CivicTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            l10n.allottedTokensTitle,
                            style: const TextStyle(
                              color: CivicTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Primary Ticket
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: CivicTheme.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    token.displayCode,
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: CivicTheme.primary, fontSize: 13),
                                  ),
                                  Text(
                                    token.beneficiaryName?.isNotEmpty == true
                                        ? token.beneficiaryName!
                                        : 'Primary Citizen',
                                    style: const TextStyle(fontSize: 11, color: CivicTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (token.appointmentSlot != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: CivicTheme.successSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  token.appointmentSlot!,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CivicTheme.success),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Child Tickets
                      ...token.childTokens.map((child) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: CivicTheme.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child.displayCode,
                                      style: const TextStyle(fontWeight: FontWeight.w900, color: CivicTheme.primary, fontSize: 13),
                                    ),
                                    Text(
                                      child.beneficiaryName ?? 'Accompanying Member',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: CivicTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (child.appointmentSlot != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: CivicTheme.primarySoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    child.appointmentSlot!,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CivicTheme.primary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Text(
                        l10n.distinctTokensNotice,
                        style: const TextStyle(fontSize: 10, color: CivicTheme.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action 1: Presence Check-In (Shown only on appointment day or once arrived)
        if (!isArrived)
          ElevatedButton.icon(
            key: const Key('btn_presence_checkin'),
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            label: Text(l10n.scanEntranceQr),
            onPressed: _handleCheckIn,
          ),
        const SizedBox(height: 12),

        // Action 2: "I'm on My Way" extension (+5 min) (One-time, preserved)
        OutlinedButton.icon(
          key: const Key('btn_on_my_way'),
          icon: const Icon(Icons.directions_walk, size: 22),
          label: Text(
            onMyWayClaimed ? l10n.onMyWayClaimed : l10n.onMyWayAction,
          ),
          onPressed: onMyWayClaimed ? null : _handleOnMyWay,
        ),
        const SizedBox(height: 12),

        // Action 3: Cancel Appointment (Normal citizen cancellation)
        OutlinedButton.icon(
          key: const Key('btn_cancel_appointment'),
          style: OutlinedButton.styleFrom(
            foregroundColor: CivicTheme.error,
            side: const BorderSide(color: CivicTheme.error, width: 2),
          ),
          icon: const Icon(Icons.cancel_outlined, size: 22),
          label: Text(l10n.cancelAppointment),
          onPressed: _handleCancel,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCompletionVerificationView(TokenModel token, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CivicTheme.success, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x141B7A4B),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Icon(Icons.check_circle_outline, color: CivicTheme.success, size: 60),
              ),
              const SizedBox(height: 12),
              const Text(
                'Service Completed at Counter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: CivicTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The counter officer has completed your service for Token ${token.displayCode}. Please confirm and provide feedback to complete the process:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: CivicTheme.textSecondary),
              ),
              const SizedBox(height: 18),
              const Divider(color: CivicTheme.border),
              const SizedBox(height: 14),

              // Question: Was your service completed successfully?
              const Text(
                'Was your service completed successfully?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CivicTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'શું તમારી સેવા સફળતાપૂર્વક પૂર્ણ થઈ?',
                style: TextStyle(fontSize: 13, color: CivicTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _serviceCompletedYes = true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _serviceCompletedYes ? CivicTheme.successSoft : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _serviceCompletedYes ? CivicTheme.success : CivicTheme.border,
                            width: _serviceCompletedYes ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: _serviceCompletedYes ? CivicTheme.success : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Yes / હા',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _serviceCompletedYes ? CivicTheme.success : CivicTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _serviceCompletedYes = false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_serviceCompletedYes ? CivicTheme.errorSoft : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_serviceCompletedYes ? CivicTheme.error : CivicTheme.border,
                            width: !_serviceCompletedYes ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cancel,
                              size: 20,
                              color: !_serviceCompletedYes ? CivicTheme.error : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No / ના',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: !_serviceCompletedYes ? CivicTheme.error : CivicTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // If No: Reason why
              if (!_serviceCompletedYes) ...[
                const SizedBox(height: 16),
                const Text(
                  'Why was the service not completed?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CivicTheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'This helps us improve government civic centres and queue management:',
                  style: TextStyle(fontSize: 12, color: CivicTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (val) => _reasonIfNot = val,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g., Documents missing, counter officer left, server down...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(color: CivicTheme.border),
              const SizedBox(height: 14),

              // Star Rating
              const Text(
                'Rate Your Service Experience / અનુભવનું રેટિંગ આપો',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CivicTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      starNum <= _ratingStars ? Icons.star : Icons.star_border,
                      color: starNum <= _ratingStars ? Colors.amber.shade700 : Colors.grey.shade400,
                    ),
                    onPressed: () => setState(() => _ratingStars = starNum),
                  );
                }),
              ),
              Center(
                child: Text(
                  _ratingStars == 5
                      ? '⭐⭐⭐⭐⭐ Excellent (5/5)'
                      : _ratingStars == 4
                          ? '⭐⭐⭐⭐ Very Good (4/5)'
                          : _ratingStars == 3
                              ? '⭐⭐⭐ Average (3/5)'
                              : _ratingStars == 2
                                  ? '⭐⭐ Needs Improvement (2/5)'
                                  : '⭐ Poor (1/5)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Feedback Comments
              TextField(
                onChanged: (val) => _feedbackComments = val,
                decoration: InputDecoration(
                  hintText: 'Additional feedback or suggestions (Optional)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 22),
              // Submit Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: CivicTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _submittingConfirmation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 22),
                label: Text(
                  _submittingConfirmation ? 'Submitting...' : 'Submit & Return to Civic Centres',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: _submittingConfirmation ? null : () => _handleConfirmCompletion(token),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveTokenView(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 80, color: CivicTheme.border),
            const SizedBox(height: 20),
            Text(
              l10n.noActiveAppointment,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: CivicTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.welcomeSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: CivicTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month, size: 24),
              label: Text(l10n.bookSlot),
              onPressed: () {
                context.push('/select-city');
              },
            ),
          ],
        ),
      ),
    );
  }
}
