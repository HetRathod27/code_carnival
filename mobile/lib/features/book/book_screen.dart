import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/client.dart';
import '../../core/theme.dart';

String _generateUuidV4() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  values[6] = (values[6] & 0x0f) | 0x40; // Version 4
  values[8] = (values[8] & 0x3f) | 0x80; // Variant 10
  final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

class BookScreen extends StatefulWidget {
  final String officeId;
  final String serviceId;
  final ApiClient? client;

  const BookScreen({
    super.key,
    required this.officeId,
    required this.serviceId,
    this.client,
  });

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();
  ServiceModel? _service;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  // Form state
  bool _documentsConfirmed = false;
  String _category = 'NORMAL';
  String? _priorityDocType;
  final TextEditingController _beneficiaryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _beneficiaryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('ql_phone') ?? '+919876543210';
      _phoneController.text = savedPhone;

      final services = await _client.fetchServices(widget.officeId);
      final found = services.firstWhere(
        (s) => s.id == widget.serviceId,
        orElse: () => throw Exception('Service not found'),
      );

      if (mounted) {
        setState(() {
          _service = found;
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

  Future<void> _handleBook() async {
    if (!_documentsConfirmed) return;

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Please enter phone number');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      var authToken = prefs.getString('ql_token');

      if (authToken == null || authToken.isEmpty) {
        authToken = await _client.getDevToken(phone: phone, role: 'CITIZEN');
        await prefs.setString('ql_token', authToken);
      }

      final idempotencyKey = _generateUuidV4();
      final token = await _client.bookToken(
        token: authToken,
        officeId: widget.officeId,
        serviceId: widget.serviceId,
        category: _category,
        phone: phone,
        beneficiaryName: _beneficiaryController.text.trim().isNotEmpty
            ? _beneficiaryController.text.trim()
            : null,
        priorityDocType: _category == 'PRIORITY' ? (_priorityDocType ?? 'SENIOR_CITIZEN') : null,
        idempotencyKey: idempotencyKey,
      );

      if (mounted) {
        _showSuccessDialog(token);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _submitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(TokenModel token) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: CivicTheme.success, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.bookingConfirmationTitle)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                token.displayCode,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: CivicTheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.bookingSuccessMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: CivicTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CivicTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.waitingAhead, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${token.waitingAhead}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/home');
              },
              child: Text(l10n.viewTokenAction),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookSlot),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _service == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: CivicTheme.error),
                        const SizedBox(height: 16),
                        Text(_error ?? 'Service not available'),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: Text(l10n.retryAction)),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Service Header Card
                        _buildServiceBanner(_service!, currentLang),
                        const SizedBox(height: 20),

                        // Document Checklist (Spec Rule 14 & Principle 14)
                        _buildDocumentChecklist(_service!, l10n),
                        const SizedBox(height: 20),

                        // Category Selector (Normal / Priority)
                        if (_service!.priorityAllowed) ...[
                          _buildCategorySelector(l10n),
                          const SizedBox(height: 20),
                        ],

                        // Applicant Information Card
                        _buildApplicantForm(l10n),
                        const SizedBox(height: 20),

                        // Error Banner if present
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CivicTheme.errorSoft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: CivicTheme.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: CivicTheme.error),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: CivicTheme.error, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Submit Button (Strictly gated on _documentsConfirmed)
                        ElevatedButton.icon(
                          icon: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_outline, size: 22),
                          label: Text(
                            _submitting ? 'Booking…' : l10n.bookAppointmentAction,
                          ),
                          onPressed: (_documentsConfirmed && !_submitting) ? _handleBook : null,
                        ),
                        if (!_documentsConfirmed) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.confirmDocumentsPrompt,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: CivicTheme.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildServiceBanner(ServiceModel service, String currentLang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CivicTheme.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CivicTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  service.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '~${service.priorAvgMinutes.round()} min average',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CivicTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.localizedName(currentLang),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: CivicTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentChecklist(ServiceModel service, AppLocalizations l10n) {
    final docs = service.requiredDocs.isNotEmpty
        ? service.requiredDocs
        : [
            {'name': 'Valid Identity Proof (Voter ID / Driving License / PAN)'},
            {'name': 'Proof of Address (Utility bill / Rent agreement)'},
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CivicTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivicTheme.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: CivicTheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.documentChecklistTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CivicTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.documentChecklistSubtitle,
            style: const TextStyle(fontSize: 14, color: CivicTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ...docs.map((doc) {
            final docName = doc is Map ? (doc['name'] ?? doc.toString()) : doc.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 20, color: CivicTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      docName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CivicTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: CivicTheme.border),
          const SizedBox(height: 8),
          // Mandatory confirmation checkbox
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              key: const Key('mandatory_document_checkbox'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.confirmDocumentsPrompt,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CivicTheme.textPrimary,
                ),
              ),
              value: _documentsConfirmed,
              activeColor: CivicTheme.primary,
              onChanged: (val) {
                setState(() {
                  _documentsConfirmed = val ?? false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CivicTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivicTheme.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.categorySelectionTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CivicTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(l10n.categoryNormalLabel),
                  selected: _category == 'NORMAL',
                  onSelected: (selected) {
                    if (selected) setState(() => _category = 'NORMAL');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: Text(l10n.categoryPriorityLabel),
                  selected: _category == 'PRIORITY',
                  onSelected: (selected) {
                    if (selected) setState(() => _category = 'PRIORITY');
                  },
                ),
              ),
            ],
          ),
          if (_category == 'PRIORITY') ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CivicTheme.accentSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CivicTheme.accent.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Color(0xFF9E6000)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.categoryPriorityNotice,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9E6000),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _priorityDocType ?? 'SENIOR_CITIZEN',
                    decoration: const InputDecoration(
                      labelText: 'Eligibility Category',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SENIOR_CITIZEN', child: Text('Senior Citizen (60+ years)')),
                      DropdownMenuItem(value: 'PREGNANT', child: Text('Pregnant / Nursing Mother')),
                      DropdownMenuItem(value: 'DISABILITY', child: Text('Person with Disability (PwD)')),
                      DropdownMenuItem(value: 'MEDICAL', child: Text('Medical Urgency / Health')),
                    ],
                    onChanged: (val) {
                      setState(() => _priorityDocType = val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicantForm(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CivicTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivicTheme.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Applicant Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CivicTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _beneficiaryController,
            decoration: InputDecoration(
              labelText: l10n.beneficiaryNameLabel,
              hintText: l10n.beneficiaryNameHint,
              prefixIcon: const Icon(Icons.person_outline, color: CivicTheme.primary),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneNumber,
              prefixIcon: const Icon(Icons.phone_outlined, color: CivicTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
