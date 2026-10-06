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

  // Slot & Schedule state (Spec Section 6 & 7)
  int _selectedDayIndex = 0; // 0 = Today, 1 = Tomorrow, 2 = In 2 Days, 3 = In 3 Days
  String _selectedSlotTime = '09:30 AM – 10:30 AM';
  int _familyCount = 1;

  String _getDayLabel(int index) {
    final now = DateTime.now();
    final target = now.add(Duration(days: index));
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = index == 0 ? 'Today' : (index == 1 ? 'Tomorrow' : weekdays[target.weekday - 1]);
    return '$dayName, ${target.day} ${months[target.month - 1]}';
  }

  List<Map<String, dynamic>> _getSlotsForDay(int dayIndex) {
    return [
      {'time': '09:30 AM – 10:30 AM', 'available': true},
      {'time': '10:30 AM – 11:30 AM', 'available': true},
      {'time': '11:30 AM – 12:30 PM', 'available': dayIndex != 0}, // Full today to demonstrate rule
      {'time': '02:00 PM – 03:00 PM', 'available': true},
      {'time': '03:00 PM – 04:00 PM', 'available': dayIndex != 1}, // Full tomorrow
      {'time': '04:30 PM – 05:30 PM', 'available': true},
    ];
  }

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
                  color: CivicTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CivicTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date:', style: TextStyle(color: CivicTheme.textSecondary, fontSize: 13)),
                        Text(_getDayLabel(_selectedDayIndex), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Slot Time:', style: TextStyle(color: CivicTheme.textSecondary, fontSize: 13)),
                        Text(_selectedSlotTime, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Party Size:', style: TextStyle(color: CivicTheme.textSecondary, fontSize: 13)),
                        Text('$_familyCount person(s)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Applicable Fee:', style: TextStyle(color: CivicTheme.textSecondary, fontSize: 13)),
                        Text(
                          _selectedDayIndex < 2 ? '₹0 (Normal Slot)' : '₹50 (Custom Slot)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: _selectedDayIndex < 2 ? CivicTheme.success : CivicTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                          onPressed: (_documentsConfirmed && !_submitting) ? _openTimeSelectionSheet : null,
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

  void _openTimeSelectionSheet() {
    DateTime selectedDate = DateTime.now().add(Duration(days: _selectedDayIndex));
    String selectedSlotTime = _selectedSlotTime;
    int familyCount = _familyCount;
    String? localNotice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final selectedStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
            final diffDays = selectedStart.difference(todayStart).inDays;
            final isCustomSlot = diffDays >= 2;
            final slots = _getSlotsForDay(diffDays < 0 ? 0 : diffDays);

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: CivicTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: CivicTheme.primary, size: 26),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Choose Date & Time Slot',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: CivicTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Calendar & Date Picker Row
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CivicTheme.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Selected Date',
                                        style: TextStyle(fontSize: 12, color: CivicTheme.textSecondary, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatFullDate(selectedDate, diffDays),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: CivicTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CivicTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.edit_calendar, size: 18),
                                  label: const Text('Open Calendar'),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate.isBefore(now) ? now : selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 30)),
                                    );
                                    if (picked != null) {
                                      setSheetState(() {
                                        selectedDate = picked;
                                        localNotice = null;
                                        final newDiff = DateTime(picked.year, picked.month, picked.day)
                                            .difference(todayStart)
                                            .inDays;
                                        final newSlots = _getSlotsForDay(newDiff < 0 ? 0 : newDiff);
                                        final isAvail = newSlots.any(
                                          (s) => s['time'] == selectedSlotTime && (s['available'] as bool),
                                        );
                                        if (!isAvail) {
                                          final firstAvail = newSlots.firstWhere(
                                            (s) => s['available'] as bool,
                                            orElse: () => newSlots.first,
                                          );
                                          selectedSlotTime = firstAvail['time'] as String;
                                        }
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Quick Date Chips
                          const Text(
                            'Quick Selection',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CivicTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickDateChip(
                                  label: 'Today',
                                  subtext: 'Within 2 Days • ₹0 Fee',
                                  isSelected: diffDays == 0,
                                  onTap: () {
                                    setSheetState(() {
                                      selectedDate = now;
                                      localNotice = null;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildQuickDateChip(
                                  label: 'Tomorrow',
                                  subtext: 'Within 2 Days • ₹0 Fee',
                                  isSelected: diffDays == 1,
                                  onTap: () {
                                    setSheetState(() {
                                      selectedDate = now.add(const Duration(days: 1));
                                      localNotice = null;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildQuickDateChip(
                                  label: 'In 2 Days',
                                  subtext: 'Custom Date • ₹50 Fee',
                                  isSelected: diffDays == 2,
                                  onTap: () {
                                    setSheetState(() {
                                      selectedDate = now.add(const Duration(days: 2));
                                      localNotice = null;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildQuickDateChip(
                                  label: 'In 3 Days',
                                  subtext: 'Custom Date • ₹50 Fee',
                                  isSelected: diffDays == 3,
                                  onTap: () {
                                    setSheetState(() {
                                      selectedDate = now.add(const Duration(days: 3));
                                      localNotice = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Dynamic Fee Tier Banner
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCustomSlot ? CivicTheme.warningSoft : CivicTheme.successSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCustomSlot ? CivicTheme.warning : CivicTheme.success,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isCustomSlot ? Icons.star_outline : Icons.check_circle_outline,
                                      color: isCustomSlot ? CivicTheme.warning : CivicTheme.success,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isCustomSlot
                                            ? 'Custom Future Slot • Higher Fee (₹50)'
                                            : 'Normal Slot (Within 2 Days) • Free / ₹0 Standard Fee',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isCustomSlot ? CivicTheme.warning : CivicTheme.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isCustomSlot
                                      ? 'Statutory Disclosure (Spec Section 6.3): A custom slot fee does not protect against official department emergency closures, gazetted holidays, or government server delay.'
                                      : 'Standard near-term booking within 2 days carries no additional fee.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCustomSlot ? const Color(0xFF8A5800) : const Color(0xFF2E7D32),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Capacity Warning Notice (if citizen clicks a full slot)
                          if (localNotice != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: CivicTheme.errorSoft,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: CivicTheme.error),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: CivicTheme.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      localNotice!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: CivicTheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Time Slots Header
                          const Text(
                            'Available Time Slots',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CivicTheme.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: slots.map((slot) {
                              final timeStr = slot['time'] as String;
                              final isAvailable = slot['available'] as bool;
                              final isSelected = selectedSlotTime == timeStr && isAvailable;

                              return InkWell(
                                onTap: () {
                                  if (isAvailable) {
                                    setSheetState(() {
                                      selectedSlotTime = timeStr;
                                      localNotice = null;
                                    });
                                  } else {
                                    setSheetState(() {
                                      localNotice = 'Slots are full for this time! Please select another available slot or another day. Booking any available normal slot within 2 days carries zero extra fees.';
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 90) / 2 > 130
                                      ? (MediaQuery.of(context).size.width - 90) / 2
                                      : 140,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !isAvailable
                                        ? Colors.grey.shade100
                                        : (isSelected ? CivicTheme.primarySoft : CivicTheme.surface),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: !isAvailable
                                          ? Colors.grey.shade300
                                          : (isSelected ? CivicTheme.primary : CivicTheme.border),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: !isAvailable
                                              ? Colors.grey.shade500
                                              : (isSelected ? CivicTheme.primary : CivicTheme.textPrimary),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: !isAvailable
                                                  ? Colors.red.shade50
                                                  : (isSelected ? CivicTheme.primary.withValues(alpha: 0.15) : Colors.green.shade50),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              !isAvailable ? 'Slots Full' : 'Available',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: !isAvailable ? CivicTheme.error : CivicTheme.success,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check_circle, size: 16, color: CivicTheme.primary),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),

                          // Party Size Selector
                          const Text(
                            'How many people are coming with you? (Spec Section 7.2)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: CivicTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [1, 2, 3, 4, 5].map((count) {
                              final isSelected = familyCount == count;
                              return ChoiceChip(
                                label: Text(count == 1 ? '1 Person' : '$count People'),
                                selected: isSelected,
                                selectedColor: CivicTheme.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : CivicTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (val) {
                                  if (val) setSheetState(() => familyCount = count);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Confirmation Action Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 22),
                    label: Text(
                      isCustomSlot
                          ? 'Confirm Appointment • Higher Fee: ₹50'
                          : 'Confirm Appointment • Standard Fee: ₹0',
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      setState(() {
                        _selectedDayIndex = diffDays;
                        _selectedSlotTime = selectedSlotTime;
                        _familyCount = familyCount;
                      });
                      _handleBook();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatFullDate(DateTime date, int diffDays) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final relative = diffDays == 0 ? ' (Today)' : (diffDays == 1 ? ' (Tomorrow)' : ' (In $diffDays Days)');
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}$relative';
  }

  Widget _buildQuickDateChip({
    required String label,
    required String subtext,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CivicTheme.primary : CivicTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? CivicTheme.primary : CivicTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? Colors.white : CivicTheme.textPrimary,
              ),
            ),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : CivicTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
