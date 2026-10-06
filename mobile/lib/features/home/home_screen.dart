import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
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
            context.go('/offices');
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

    final controller = TextEditingController(text: '${token.businessDate}:${token.officeId}:demo_qr_secret_key_123');
    final l10n = AppLocalizations.of(context)!;

    final qrPayload = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: CivicTheme.primary),
            const SizedBox(width: 8),
            Text(l10n.checkInQr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.enterQrCodePrompt,
              style: const TextStyle(fontSize: 15, color: CivicTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'QR Payload',
                prefixIcon: Icon(Icons.qr_code, color: CivicTheme.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Verify Arrival'),
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
            Text(l10n.cancelAppointment),
          ],
        ),
        content: Text(l10n.confirmCancelPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CivicTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel'),
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
          const SnackBar(content: Text('Appointment successfully cancelled')),
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
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
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
    final isArrived = token.arrivedAt != null;
    final onMyWayClaimed = token.onMyWayAt != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                l10n.myToken.toUpperCase(),
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
                      color: CivicTheme.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      token.state,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CivicTheme.primary,
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
                      child: const Text(
                        '⭐ Priority',
                        style: TextStyle(
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
                    Text(
                      isArrived ? l10n.presenceVerified : 'Not Yet Checked In',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isArrived ? CivicTheme.success : CivicTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: CivicTheme.border),
              const SizedBox(height: 12),
              // Queue metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.waitingAhead, style: const TextStyle(fontSize: 16)),
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
                    Text(l10n.nowServingAt, style: const TextStyle(fontSize: 16)),
                    Text(
                      '${token.nowServing}${token.counterLabel != null ? " (${token.counterLabel})" : ""}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CivicTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.estimatedTurn, style: const TextStyle(fontSize: 16)),
                  Text(
                    token.lastEtaMinutes != null
                        ? '~${token.lastEtaMinutes!.round()} ${l10n.minutesUnit}'
                        : 'Calculating…',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              // ETA Range (p50 / low / high)
              if (token.etaLow != null && token.etaHigh != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.etaRangePrefix, style: const TextStyle(fontSize: 14, color: CivicTheme.textSecondary)),
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
          ),
        ),
        const SizedBox(height: 20),

        // Action 1: Presence Check-In
        if (!isArrived)
          ElevatedButton.icon(
            key: const Key('btn_presence_checkin'),
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            label: Text(l10n.scanEntranceQr),
            onPressed: _handleCheckIn,
          ),
        const SizedBox(height: 12),

        // Action 2: "I'm on My Way" extension (+5 min)
        OutlinedButton.icon(
          key: const Key('btn_on_my_way'),
          icon: const Icon(Icons.directions_walk, size: 22),
          label: Text(
            onMyWayClaimed ? l10n.onMyWayClaimed : l10n.onMyWayAction,
          ),
          onPressed: onMyWayClaimed ? null : _handleOnMyWay,
        ),
        const SizedBox(height: 12),

        // Action 3: Cancel Appointment
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

  Widget _buildNoActiveTokenView(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 80, color: CivicTheme.border),
            const SizedBox(height: 20),
            const Text(
              'No Active Appointment',
              style: TextStyle(
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
                context.push('/offices');
              },
            ),
          ],
        ),
      ),
    );
  }
}
