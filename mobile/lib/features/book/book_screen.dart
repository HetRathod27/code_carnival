import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/client.dart';
import '../../core/theme.dart';
import '../../core/office_names.dart';
import '../policies/policies_screen.dart';

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
  final Set<int> _checkedDocIndices = {};
  bool _documentsConfirmed = false;

  List<dynamic> _getRequiredDocs() {
    if (_service == null) return const [];
    return _service!.requiredDocs.isNotEmpty
        ? _service!.requiredDocs
        : const [
            {'name': 'Valid Identity Proof (Voter ID / Driving License / PAN)'},
            {'name': 'Proof of Address (Utility bill / Rent agreement)'},
          ];
  }

  bool get _isChecklistComplete {
    final docs = _getRequiredDocs();
    final allDocsChecked = docs.isEmpty || _checkedDocIndices.length >= docs.length;
    return _documentsConfirmed && allDocsChecked;
  }
  final String _category = 'NORMAL';
  String? _priorityDocType;
  final TextEditingController _beneficiaryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Slot & Schedule state (Spec Section 6 & 7)
  int _selectedDayIndex =
      DateTime.now().hour >= 18 ? 1 : 0; // If past 6 PM, default to Tomorrow
  String _selectedSlotTime = '09:30 AM – 10:30 AM';
  int _familyCount = 1;

  // Accompanying persons state (Max 4 people total: primary applicant + up to 3 accompanying)
  final List<TextEditingController> _accompanyingNameControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  List<String?> _accompanyingReasonKeys = [null, null, null];

  List<String?> get _safeAccompanyingReasonKeys {
    if (_accompanyingReasonKeys.isEmpty || _accompanyingReasonKeys.length < 3) {
      _accompanyingReasonKeys = [null, null, null];
    }
    return _accompanyingReasonKeys;
  }

  String _getReasonLabel(String? key, AppLocalizations l10n) {
    switch (key) {
      case 'joint_applicant':
        return l10n.reasonJointApplicant;
      case 'assistance':
        return l10n.reasonAssistance;
      case 'guardian':
        return l10n.reasonGuardian;
      case 'witness':
        return l10n.reasonWitnessSignatory;
      case 'family_verification':
        return l10n.reasonFamilyVerification;
      case 'other_counter':
        return l10n.reasonOtherCounterWork;
      default:
        return key ?? '';
    }
  }

  String? _getAccompanyingValidationError(int count, AppLocalizations l10n) {
    if (count <= 1) return null;
    final needed = count - 1;
    for (int i = 0; i < needed; i++) {
      final name = _accompanyingNameControllers[i].text.trim();
      final reason = _safeAccompanyingReasonKeys[i];
      if (name.isEmpty) {
        return l10n.missingAccompanyingDetailsPrompt;
      }
      if (reason == null || reason.isEmpty) {
        return l10n.missingAccompanyingDetailsPrompt;
      }
      if (reason == 'other_counter') {
        return l10n.invalidCounterReasonError;
      }
    }
    return null;
  }

  String _calculateStaggeredSlotTime(String baseSlot, int offsetIndex) {
    try {
      final dash = baseSlot.contains('–') ? '–' : (baseSlot.contains('-') ? '-' : null);
      final startPart = dash != null ? baseSlot.split(dash)[0].trim() : baseSlot.trim();
      final regex = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
      final match = regex.firstMatch(startPart);
      if (match != null) {
        var hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final meridiem = match.group(3)!.toUpperCase();
        if (meridiem == 'PM' && hour != 12) {
          hour += 12;
        } else if (meridiem == 'AM' && hour == 12) {
          hour = 0;
        }
        final totalMinutes = hour * 60 + minute + offsetIndex * 15;
        final sHour = (totalMinutes ~/ 60) % 24;
        final sMin = totalMinutes % 60;
        final eTotal = totalMinutes + 15;
        final eHour = (eTotal ~/ 60) % 24;
        final eMin = eTotal % 60;

        String fmt(int h, int m) {
          final med = h < 12 ? 'AM' : 'PM';
          var h12 = h % 12;
          if (h12 == 0) h12 = 12;
          return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $med';
        }

        return '${fmt(sHour, sMin)} – ${fmt(eHour, eMin)}';
      }
    } catch (_) {}
    if (offsetIndex == 0) return baseSlot;
    return '$baseSlot (+${offsetIndex * 15}m)';
  }

  String _getDayLabel(
    int index, [
    String currentLang = 'en',
    AppLocalizations? l10n,
  ]) {
    final now = DateTime.now();
    final target = now.add(Duration(days: index));
    final enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final guWeekdays = ['સોમ', 'મંગળ', 'બુધ', 'ગુરુ', 'શુક્ર', 'શનિ', 'રવિ'];
    final hiWeekdays = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
    final enMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final guMonths = [
      'જાન્યુ',
      'ફેબ્રુ',
      'માર્ચ',
      'એપ્રિલ',
      'મે',
      'જૂન',
      'જુલાઈ',
      'ઓગસ્ટ',
      'સપ્ટે',
      'ઓક્ટો',
      'નવે',
      'ડિસે',
    ];
    final hiMonths = [
      'जनवरी',
      'फ़रवरी',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अगस्त',
      'सितंबर',
      'अक्टूबर',
      'नवंबर',
      'दिसंबर',
    ];

    final weekdays = currentLang == 'gu'
        ? guWeekdays
        : (currentLang == 'hi' ? hiWeekdays : enWeekdays);
    final months = currentLang == 'gu'
        ? guMonths
        : (currentLang == 'hi' ? hiMonths : enMonths);

    final String dayName;
    if (index == 0) {
      dayName =
          l10n?.todayLabel ??
          (currentLang == 'gu'
              ? 'આજે'
              : (currentLang == 'hi' ? 'आज' : 'Today'));
    } else if (index == 1) {
      dayName =
          l10n?.tomorrowLabel ??
          (currentLang == 'gu'
              ? 'આવતીકાલે'
              : (currentLang == 'hi' ? 'कल' : 'Tomorrow'));
    } else {
      dayName = weekdays[target.weekday - 1];
    }
    return '$dayName, ${target.day} ${months[target.month - 1]}';
  }


  List<SlotItemModel> _getFallbackSlots() {
    return [
      SlotItemModel(slotTime: '09:30 AM – 10:30 AM', startTime: '09:30:00', endTime: '10:30:00', available: true, status: 'AVAILABLE', reasonCode: 'AVAILABLE', remainingCapacity: 4, bookedCount: 0, totalCapacity: 4),
      SlotItemModel(slotTime: '10:30 AM – 11:30 AM', startTime: '10:30:00', endTime: '11:30:00', available: true, status: 'AVAILABLE', reasonCode: 'AVAILABLE', remainingCapacity: 4, bookedCount: 0, totalCapacity: 4),
      SlotItemModel(slotTime: '11:30 AM – 12:30 PM', startTime: '11:30:00', endTime: '12:30:00', available: true, status: 'AVAILABLE', reasonCode: 'AVAILABLE', remainingCapacity: 4, bookedCount: 0, totalCapacity: 4),
      SlotItemModel(slotTime: '02:00 PM – 03:00 PM', startTime: '14:00:00', endTime: '15:00:00', available: true, status: 'AVAILABLE', reasonCode: 'AVAILABLE', remainingCapacity: 4, bookedCount: 0, totalCapacity: 4),
      SlotItemModel(slotTime: '03:00 PM – 04:00 PM', startTime: '15:00:00', endTime: '16:00:00', available: true, status: 'AVAILABLE', reasonCode: 'AVAILABLE', remainingCapacity: 4, bookedCount: 0, totalCapacity: 4),
      SlotItemModel(slotTime: '04:30 PM – 05:30 PM', startTime: '16:30:00', endTime: '17:30:00', available: true, status: 'AVAILABLE', reasonCode: 'AVAILABLE', remainingCapacity: 4, bookedCount: 0, totalCapacity: 4),
    ];
  }

  String _getSlotStatusLabel(SlotItemModel slot, AppLocalizations l10n) {
    switch (slot.status) {
      case 'OFFICE_CLOSED':
        return l10n.slotOfficeClosed;
      case 'BOOKING_CLOSED':
        return l10n.slotBookingClosed;
      case 'TIME_PASSED':
        return l10n.slotTimePassed;
      case 'FULLY_BOOKED':
        return l10n.slotFullyBooked;
      case 'INSUFFICIENT_GROUP_SLOTS':
        return l10n.slotInsufficientGroupSlots;
      case 'AVAILABLE':
      default:
        return l10n.slotAvailable;
    }
  }

  String _getSlotErrorMessage(SlotItemModel slot, AppLocalizations l10n) {
    switch (slot.status) {
      case 'OFFICE_CLOSED':
        return l10n.slotOfficeClosedError;
      case 'BOOKING_CLOSED':
        return l10n.slotBookingClosedError;
      case 'TIME_PASSED':
        return l10n.slotTimePassedError;
      case 'FULLY_BOOKED':
        return l10n.slotFullyBookedError;
      case 'INSUFFICIENT_GROUP_SLOTS':
        return l10n.slotGroupUnavailableError;
      default:
        return l10n.slotNoLongerAvailable;
    }
  }

  Widget _buildSlotStatusBadge(SlotItemModel slot, AppLocalizations l10n, bool isSelected) {
    IconData icon;
    String text;
    Color badgeColor;
    Color textColor;

    switch (slot.status) {
      case 'OFFICE_CLOSED':
        icon = Icons.domain_disabled;
        text = l10n.slotOfficeClosed;
        badgeColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case 'BOOKING_CLOSED':
        icon = Icons.lock_clock;
        text = l10n.slotBookingClosed;
        badgeColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        break;
      case 'TIME_PASSED':
        icon = Icons.schedule;
        text = l10n.slotTimePassed;
        badgeColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case 'FULLY_BOOKED':
        icon = Icons.block;
        text = l10n.slotFullyBooked;
        badgeColor = Colors.red.shade50;
        textColor = CivicTheme.error;
        break;
      case 'INSUFFICIENT_GROUP_SLOTS':
        icon = Icons.group_off_outlined;
        text = l10n.slotInsufficientGroupSlots;
        badgeColor = Colors.amber.shade50;
        textColor = const Color(0xFF8A5800);
        break;
      case 'AVAILABLE':
      default:
        icon = Icons.check_circle_outline;
        text = l10n.slotAvailable;
        badgeColor = isSelected ? CivicTheme.primary.withValues(alpha: 0.15) : Colors.green.shade50;
        textColor = isSelected ? CivicTheme.primary : CivicTheme.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
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
    for (final c in _accompanyingNameControllers) {
      c.dispose();
    }
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
      final savedName = prefs.getString('ql_user_name') ?? '';
      if (savedName.isNotEmpty && _beneficiaryController.text.isEmpty) {
        _beneficiaryController.text = savedName;
      }
      // Language is determined reactively via Localizations.localeOf(context)

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
    if (!_isChecklistComplete) return;

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Please enter phone number');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    if (_service != null && !_service!.isCounterOpen) {
      setState(() => _error = _service!.isCounterClosed ? l10n.counterClosedNotice : l10n.counterOnBreakNotice);
      return;
    }

    if (_selectedDayIndex > 15) {
      setState(() => _error = l10n.dateExceeds15DaysError);
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

      final date = DateTime.now().add(Duration(days: _selectedDayIndex));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final accompanyingMembers = <Map<String, dynamic>>[];
      if (_familyCount > 1) {
        for (int i = 0; i < _familyCount - 1; i++) {
          final accName = _accompanyingNameControllers[i].text.trim();
          final accReason = _safeAccompanyingReasonKeys[i] ?? '';
          final childSlot = _calculateStaggeredSlotTime(_selectedSlotTime, i + 1);
          accompanyingMembers.add({
            'name': accName,
            'reason': accReason,
            'slot_time': childSlot,
          });
        }
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
        priorityDocType: _category == 'PRIORITY'
            ? (_priorityDocType ?? 'SENIOR_CITIZEN')
            : null,
        appointmentDate: dateStr,
        appointmentSlot: _selectedSlotTime,
        isFixed: true,
        accompanyingMembers: accompanyingMembers.isNotEmpty ? accompanyingMembers : null,
        idempotencyKey: idempotencyKey,
      );

      if (mounted) {
        setState(() => _submitting = false);
        _showSuccessDialog(token);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('COUNTER_CLOSED')) {
          errorMsg = l10n.counterClosedNotice;
        } else if (errorMsg.contains('COUNTER_ON_BREAK')) {
          errorMsg = l10n.counterOnBreakNotice;
        } else if (errorMsg.contains('SLOT_TIME_PASSED')) {
          errorMsg = l10n.slotTimePassedError;
        } else if (errorMsg.contains('SLOT_FULLY_BOOKED')) {
          errorMsg = l10n.slotFullyBookedError;
        } else if (errorMsg.contains('SLOT_INSUFFICIENT_GROUP_SLOTS')) {
          errorMsg = l10n.slotGroupUnavailableError;
        } else if (errorMsg.contains('SLOT_OFFICE_CLOSED')) {
          errorMsg = l10n.slotOfficeClosedError;
        } else if (errorMsg.contains('BOOKING_CLOSED')) {
          errorMsg = l10n.slotBookingClosedError;
        }
        setState(() {
          _error = errorMsg;
          _submitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(TokenModel token) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = Localizations.localeOf(context).languageCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: CivicTheme.success,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.bookingConfirmationTitle)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
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
                style: const TextStyle(
                  fontSize: 16,
                  color: CivicTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CivicTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CivicTheme.border),
                ),
                child: Column(
                  children: [
                    // Civic Centre
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.civicCentreLabel,
                          style: const TextStyle(
                            color: CivicTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            OfficeNames.getHumanOfficeName(
                              widget.officeId,
                              lang: currentLang,
                            ),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: CivicTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Service
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.serviceLabel,
                          style: const TextStyle(
                            color: CivicTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _service?.localizedName(currentLang) ?? widget.serviceId,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: CivicTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Token Code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.tokenLabel,
                          style: const TextStyle(
                            color: CivicTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          token.displayCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: CivicTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.dateSummaryLabel,
                            style: const TextStyle(
                              color: CivicTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          _getDayLabel(_selectedDayIndex, currentLang, l10n),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Fixed Slot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.slotTimeSummaryLabel,
                            style: const TextStyle(
                              color: CivicTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          _selectedSlotTime,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Party Size
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.partySizeSummaryLabel,
                            style: const TextStyle(
                              color: CivicTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          _familyCount == 1
                              ? l10n.onePerson
                              : l10n.multiplePeople(_familyCount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (_familyCount > 1) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CivicTheme.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CivicTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.confirmation_number_outlined, size: 16, color: CivicTheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.allottedTokensTitle,
                                  style: const TextStyle(
                                    color: CivicTheme.primary,
                                    fontSize: 12,
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
                                          _beneficiaryController.text.trim().isNotEmpty
                                              ? _beneficiaryController.text.trim()
                                              : 'Primary Citizen',
                                          style: const TextStyle(fontSize: 11, color: CivicTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: CivicTheme.successSoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      token.appointmentSlot ?? _calculateStaggeredSlotTime(_selectedSlotTime, 0),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CivicTheme.success),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Child Tickets
                            ...List.generate(_familyCount - 1, (i) {
                              final name = _accompanyingNameControllers[i].text.trim();
                              final reasonLabel = _getReasonLabel(
                                _safeAccompanyingReasonKeys[i],
                                l10n,
                              );
                              final childCode = token.childTokens.length > i
                                  ? token.childTokens[i].displayCode
                                  : '${token.displayCode.split('-').first}-${(token.seq + i + 1).toString().padLeft(3, '0')}';
                              final childSlot = token.childTokens.length > i && token.childTokens[i].appointmentSlot != null
                                  ? token.childTokens[i].appointmentSlot!
                                  : _calculateStaggeredSlotTime(_selectedSlotTime, i + 1);

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
                                            childCode,
                                            style: const TextStyle(fontWeight: FontWeight.w900, color: CivicTheme.primary, fontSize: 13),
                                          ),
                                          Text(
                                            '$name ($reasonLabel)',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, color: CivicTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: CivicTheme.primarySoft,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        childSlot,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CivicTheme.primary),
                                      ),
                                    ),
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
                    const SizedBox(height: 8),
                    // Fee Tier & Notice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.feeLabel,
                            style: const TextStyle(
                              color: CivicTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          _selectedDayIndex < 2
                              ? l10n.standardFreeTier
                              : l10n.customPaidTier,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: _selectedDayIndex < 2
                                ? CivicTheme.success
                                : CivicTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Truthful Fee Disclosure
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedDayIndex < 2
                      ? CivicTheme.successSoft
                      : CivicTheme.warningSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedDayIndex < 2
                      ? l10n.feeFreeNotice
                      : l10n.feeDemoNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _selectedDayIndex < 2
                        ? const Color(0xFF1B7A4B)
                        : const Color(0xFF8A5800),
                  ),
                ),
              ),
              // Live waiting status is ONLY shown if appointment is for TODAY
              if (_selectedDayIndex == 0 && token.waitingAhead > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CivicTheme.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.waitingAhead,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${token.waitingAhead}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
      appBar: AppBar(title: Text(l10n.bookSlot)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _service == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: CivicTheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(_error ?? 'Service not available'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: Text(l10n.retryAction),
                    ),
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
                    _buildDocumentChecklist(_service!, l10n, currentLang),
                    const SizedBox(height: 20),

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
                          border: Border.all(
                            color: CivicTheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: CivicTheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: CivicTheme.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Submit Button (Strictly gated on _isChecklistComplete)
                    ElevatedButton.icon(
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 22),
                      label: Text(
                        _submitting ? 'Booking…' : l10n.bookAppointmentAction,
                      ),
                      onPressed: (_isChecklistComplete && !_submitting && (_service?.isCounterOpen ?? true))
                          ? () => _openTimeSelectionSheet(l10n, currentLang)
                          : null,
                    ),
                    if (_service != null && !_service!.isCounterOpen) ...[
                      const SizedBox(height: 8),
                      Text(
                        _service!.isCounterClosed
                            ? l10n.counterClosedNotice
                            : l10n.counterOnBreakNotice,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _service!.isCounterClosed ? CivicTheme.error : const Color(0xFF856404),
                        ),
                      ),
                    ] else if (!_isChecklistComplete) ...[
                      const SizedBox(height: 8),
                      Text(
                        _checkedDocIndices.length < _getRequiredDocs().length
                            ? l10n.checkAllDocsFirstNotice
                            : l10n.confirmDocumentsPrompt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CivicTheme.textSecondary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: Text(l10n.viewAppointmentRulesAction),
                        style: TextButton.styleFrom(
                          foregroundColor: CivicTheme.primary,
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: () {
                          try {
                            context.push('/policies');
                          } catch (_) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                            );
                          }
                        },
                      ),
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
              Flexible(
                child: Text(
                  '~${service.priorAvgMinutes.round()} min average',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CivicTheme.primary,
                  ),
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
          if (!service.isCounterOpen) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: service.isCounterClosed ? Colors.grey.shade100 : const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: service.isCounterClosed ? Colors.grey.shade400 : const Color(0xFFFFEEBA),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    service.isCounterClosed ? Icons.block : Icons.coffee,
                    size: 20,
                    color: service.isCounterClosed ? Colors.grey.shade800 : const Color(0xFF856404),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      service.isCounterClosed
                          ? AppLocalizations.of(context)!.counterClosedNotice
                          : AppLocalizations.of(context)!.counterOnBreakNotice,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: service.isCounterClosed ? Colors.grey.shade800 : const Color(0xFF856404),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

  }

  String _getDocumentName(dynamic doc, String currentLang) {
    String raw = '';

    if (doc is Map) {
      final langKey = 'name_$currentLang';
      if (doc[langKey] != null && doc[langKey].toString().trim().isNotEmpty) {
        raw = doc[langKey].toString().trim();
      } else if (doc['names'] is Map) {
        final names = doc['names'] as Map;
        if (names[currentLang] != null &&
            names[currentLang].toString().trim().isNotEmpty) {
          raw = names[currentLang].toString().trim();
        } else if (names['en'] != null &&
            names['en'].toString().trim().isNotEmpty) {
          raw = names['en'].toString().trim();
        }
      } else if (doc['name_en'] != null &&
          doc['name_en'].toString().trim().isNotEmpty) {
        raw = doc['name_en'].toString().trim();
      } else if (doc['name'] != null &&
          doc['name'].toString().trim().isNotEmpty) {
        raw = doc['name'].toString().trim();
      } else if (doc['title'] != null &&
          doc['title'].toString().trim().isNotEmpty) {
        raw = doc['title'].toString().trim();
      }
    } else if (doc != null) {
      String str = doc.toString().trim();
      // If it looks like a serialized map {id: ..., name_gu: ..., name_en: ...}
      if (str.startsWith('{') && str.endsWith('}')) {
        // Try regex for name_$currentLang
        final langPattern = RegExp(
          'name_$currentLang'
          r'\s*:\s*([^,}\n]+)',
        );
        final matchLang = langPattern.firstMatch(str);
        if (matchLang != null) {
          raw = matchLang.group(1)?.trim() ?? '';
        } else {
          // Try name_en
          final enPattern = RegExp(r'name_en\s*:\s*([^,}\n]+)');
          final matchEn = enPattern.firstMatch(str);
          if (matchEn != null) {
            raw = matchEn.group(1)?.trim() ?? '';
          } else {
            // Try name:
            final namePattern = RegExp(r'name\s*:\s*([^,}\n]+)');
            final matchName = namePattern.firstMatch(str);
            if (matchName != null) {
              raw = matchName.group(1)?.trim() ?? '';
            }
          }
        }
      } else {
        raw = str;
      }
    }

    // Clean any residual symbols or key-value patterns
    raw = raw.replaceAll(RegExp(r'^\{+|\}+$'), '').trim();
    if (raw.startsWith('name:')) {
      raw = raw.substring(5).trim();
    }

    if (raw.isEmpty) {
      return currentLang == 'gu'
          ? 'જરૂરી દસ્તાવેજ'
          : (currentLang == 'hi' ? 'आवश्यक दस्तावेज़' : 'Required Document');
    }

    // Check localized fallback dictionary for standard documents
    final lower = raw.toLowerCase();
    if (currentLang == 'gu') {
      if (lower.contains('hospital') || lower.contains('discharge')) {
        return 'હોસ્પિટલ ડિસ્ચાર્જ સારાંશ / પ્રમાણપત્ર';
      }
      if (lower.contains('parent') ||
          lower.contains('aadhaar') ||
          lower.contains('photo id')) {
        return 'માતાપિતાનું ફોટો ઓળખકાર્ડ પુરાવો';
      }
      if (lower.contains('marriage')) {
        return 'લગ્ન પ્રમાણપત્ર (જો લાગુ હોય તો)';
      }
      if (lower.contains('tax') || lower.contains('receipt')) {
        return 'પાછલા વર્ષની ટેક્સ પહોંચ / રસીદ';
      }
      if (lower.contains('property') ||
          lower.contains('index') ||
          lower.contains('title')) {
        return 'મિલકત ઇન્ડેક્સ-૨ / દસ્તાવેજ';
      }
      if (lower.contains('valid photo id')) {
        return 'માન્ય ફોટો ઓળખકાર્ડ';
      }
      if (lower.contains('premises') ||
          lower.contains('rent') ||
          lower.contains('ownership')) {
        return 'જગ્યાનો ભાડા કરાર / માલિકી પુરાવો';
      }
      if (lower.contains('fire') ||
          lower.contains('emergency') ||
          lower.contains('noc')) {
        return 'ફાયર અને ઇમરજન્સી સેવાઓ તરફથી એનઓસી';
      }
      if (lower.contains('partnership') || lower.contains('incorporation')) {
        return 'ભાગીદારી ડીડ / ઇન્કોર્પોરેશન પ્રમાણપત્ર';
      }
      if (lower.contains('identity proof') || lower.contains('voter')) {
        return 'માન્ય ઓળખ પુરાવો (મતદાર કાર્ડ / ડ્રાઇવિંગ લાઇસન્સ / પાન)';
      }
      if (lower.contains('proof of address') || lower.contains('utility')) {
        return 'સરનામાનો પુરાવો (લાઇટ બિલ / ભાડા કરાર)';
      }
    } else if (currentLang == 'hi') {
      if (lower.contains('hospital') || lower.contains('discharge')) {
        return 'अस्पताल डिस्चार्ज सारांश / प्रमाण पत्र';
      }
      if (lower.contains('parent') ||
          lower.contains('aadhaar') ||
          lower.contains('photo id')) {
        return 'माता-पिता का फोटो पहचान प्रमाण';
      }
      if (lower.contains('marriage')) {
        return 'विवाह प्रमाण पत्र (यदि लागू हो)';
      }
      if (lower.contains('tax') || lower.contains('receipt')) {
        return 'पिछले वर्ष की कर रसीद';
      }
      if (lower.contains('property') ||
          lower.contains('index') ||
          lower.contains('title')) {
        return 'संपत्ति इंडेक्स-2 / शीर्षक दस्तावेज़';
      }
      if (lower.contains('valid photo id')) {
        return 'मान्य फोटो पहचान पत्र';
      }
      if (lower.contains('premises') ||
          lower.contains('rent') ||
          lower.contains('ownership')) {
        return 'परिसर किराया समझौता / स्वामित्व प्रमाण';
      }
      if (lower.contains('fire') ||
          lower.contains('emergency') ||
          lower.contains('noc')) {
        return 'अग्निशमन एवं आपातकालीन सेवाओं से एनओसी';
      }
      if (lower.contains('partnership') || lower.contains('incorporation')) {
        return 'साझेदारी विलेख / निगमन प्रमाणपत्र';
      }
      if (lower.contains('identity proof') || lower.contains('voter')) {
        return 'मान्य पहचान प्रमाण (मतदाता पहचान पत्र / ड्राइविंग लाइसेंस / पैन)';
      }
      if (lower.contains('proof of address') || lower.contains('utility')) {
        return 'पते का प्रमाण (बिजली बिल / किराया समझौता)';
      }
    }

    return raw;
  }

  Widget _buildDocumentChecklist(
    ServiceModel service,
    AppLocalizations l10n,
    String currentLang,
  ) {
    final docs = _getRequiredDocs();
    final allDocsChecked = docs.isEmpty || _checkedDocIndices.length >= docs.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CivicTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isChecklistComplete
              ? CivicTheme.success.withValues(alpha: 0.5)
              : CivicTheme.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: _isChecklistComplete ? CivicTheme.success : CivicTheme.primary,
                      size: 24,
                    ),
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
              ),
              const SizedBox(width: 8),
              // Document count progress badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: allDocsChecked
                      ? CivicTheme.successSoft
                      : CivicTheme.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: allDocsChecked
                        ? CivicTheme.success
                        : CivicTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  l10n.docsVerifiedProgress(_checkedDocIndices.length, docs.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: allDocsChecked
                        ? CivicTheme.success
                        : CivicTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.documentChecklistSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: CivicTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Every required document has its own interactive checkbox
          ...docs.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            final docName = _getDocumentName(doc, currentLang);
            final isChecked = _checkedDocIndices.contains(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isChecked
                    ? CivicTheme.primarySoft.withValues(alpha: 0.35)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _checkedDocIndices.remove(index);
                      } else {
                        _checkedDocIndices.add(index);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: Checkbox(
                            key: Key('doc_checkbox_$index'),
                            value: isChecked,
                            activeColor: CivicTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _checkedDocIndices.add(index);
                                } else {
                                  _checkedDocIndices.remove(index);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            docName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                              color: isChecked ? CivicTheme.textPrimary : CivicTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          const Divider(color: CivicTheme.border),
          const SizedBox(height: 4),
          // Mandatory declaration checkbox
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
              subtitle: !allDocsChecked
                  ? Text(
                      l10n.checkAllDocsFirstNotice,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CivicTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
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
          Text(
            l10n.applicantDetailsTitle,
            style: const TextStyle(
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
              prefixIcon: const Icon(
                Icons.person_outline,
                color: CivicTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneNumber,
              prefixIcon: const Icon(
                Icons.phone_outlined,
                color: CivicTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTimeSelectionSheet(AppLocalizations l10n, String currentLang) {
    if (_service != null && !_service!.isCounterOpen) {
      setState(() {
        _error = _service!.isCounterClosed
            ? l10n.counterClosedNotice
            : l10n.counterOnBreakNotice;
      });
      return;
    }

    DateTime selectedDate = DateTime.now().add(
      Duration(days: _selectedDayIndex),
    );
    String selectedSlotTime = _selectedSlotTime;
    int familyCount = _familyCount;
    String? localNotice;
    List<SlotItemModel> currentSlots = _getFallbackSlots();
    bool isLoadingSlots = true;
    bool hasInitiatedFetch = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setSheetState) {
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final selectedStart = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
            );
            final diffDays = selectedStart.difference(todayStart).inDays;
            final isCustomSlot = diffDays >= 2;

            Future<void> fetchSlotsForDateAndParty() async {
              final dateFormatted =
                  "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
              setSheetState(() {
                isLoadingSlots = true;
              });
              try {
                final fetched = await _client.fetchSlots(
                  officeId: widget.officeId,
                  serviceId: widget.serviceId,
                  date: dateFormatted,
                  partySize: familyCount,
                );
                try {
                  final svcs = await _client.fetchServices(widget.officeId);
                  final latest = svcs.firstWhere((s) => s.id == widget.serviceId, orElse: () => _service!);
                  if (mounted) {
                    setState(() => _service = latest);
                  }
                  if (!latest.isCounterOpen) {
                    setSheetState(() {
                      localNotice = latest.isCounterClosed ? l10n.counterClosedNotice : l10n.counterOnBreakNotice;
                    });
                  }
                } catch (_) {}
                setSheetState(() {
                  currentSlots = fetched;
                  isLoadingSlots = false;
                });
              } catch (_) {
                setSheetState(() {
                  currentSlots = _getFallbackSlots();
                  isLoadingSlots = false;
                });
              }
            }

            if (!hasInitiatedFetch) {
              hasInitiatedFetch = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                fetchSlotsForDateAndParty();
              });
            }

            return Dialog(
              backgroundColor: CivicTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 580,
                  maxHeight: 740,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: CivicTheme.primary,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.chooseDateTimeSlot,
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
                      const SizedBox(height: 4),
                      Text(
                        l10n.chooseAvailableSlotInstruction,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CivicTheme.textSecondary,
                        ),
                      ),
                      const Divider(height: 18),
                      Flexible(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.selectedDateLabel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: CivicTheme.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatFullDate(
                                              selectedDate,
                                              diffDays,
                                              currentLang,
                                              l10n,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: CivicTheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l10n.advanceLimitNotice,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: CivicTheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: CivicTheme.primary,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 44),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.edit_calendar,
                                        size: 18,
                                      ),
                                      label: Text(l10n.openCalendarAction),
                                      onPressed: () async {
                                        final todayZero = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                        );
                                        final maxAdvanceDate = todayZero.add(
                                          const Duration(days: 15),
                                        );
                                        final picked = await showDatePicker(
                                          context: sheetContext,
                                          initialDate:
                                              selectedDate.isBefore(todayZero)
                                              ? todayZero
                                              : (selectedDate.isAfter(maxAdvanceDate)
                                                  ? maxAdvanceDate
                                                  : selectedDate),
                                          firstDate: todayZero,
                                          lastDate: maxAdvanceDate,
                                        );
                                        if (picked != null) {
                                          setSheetState(() {
                                            selectedDate = picked;
                                            localNotice = null;
                                          });
                                          fetchSlotsForDateAndParty();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Quick Date Chips
                              Text(
                                l10n.quickSelectionTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CivicTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildQuickDateChip(
                                    label: l10n.todayLabel,
                                    subtext: l10n.within2DaysFeeFree,
                                    isSelected: diffDays == 0,
                                    onTap: () {
                                      setSheetState(() {
                                        selectedDate = now;
                                        localNotice = null;
                                      });
                                        fetchSlotsForDateAndParty();
                                    },
                                  ),
                                  _buildQuickDateChip(
                                    label: l10n.tomorrowLabel,
                                    subtext: l10n.within2DaysFeeFree,
                                    isSelected: diffDays == 1,
                                    onTap: () {
                                      setSheetState(() {
                                        selectedDate = now.add(
                                          const Duration(days: 1),
                                        );
                                        localNotice = null;
                                      });
                                        fetchSlotsForDateAndParty();
                                    },
                                  ),
                                  _buildQuickDateChip(
                                    label: l10n.in2DaysLabel,
                                    subtext: l10n.customDateFee50,
                                    isSelected: diffDays == 2,
                                    onTap: () {
                                      setSheetState(() {
                                        selectedDate = now.add(
                                          const Duration(days: 2),
                                        );
                                        localNotice = null;
                                      });
                                        fetchSlotsForDateAndParty();
                                    },
                                  ),
                                  _buildQuickDateChip(
                                    label: l10n.in3DaysLabel,
                                    subtext: l10n.customDateFee50,
                                    isSelected: diffDays == 3,
                                    onTap: () {
                                      setSheetState(() {
                                        selectedDate = now.add(
                                          const Duration(days: 3),
                                        );
                                        localNotice = null;
                                      });
                                        fetchSlotsForDateAndParty();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Dynamic Fee Tier Banner
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCustomSlot
                                      ? CivicTheme.warningSoft
                                      : CivicTheme.successSoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCustomSlot
                                        ? CivicTheme.warning
                                        : CivicTheme.success,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isCustomSlot
                                              ? Icons.star_outline
                                              : Icons.check_circle_outline,
                                          color: isCustomSlot
                                              ? CivicTheme.warning
                                              : CivicTheme.success,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isCustomSlot
                                                ? l10n.customSlotTitle
                                                : l10n.normalSlotTitle,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: isCustomSlot
                                                  ? CivicTheme.warning
                                                  : CivicTheme.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isCustomSlot
                                          ? l10n.statutoryDisclosure
                                          : l10n.standardNearTermNotice,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isCustomSlot
                                            ? const Color(0xFF8A5800)
                                            : const Color(0xFF2E7D32),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: CivicTheme.error,
                                        size: 20,
                                      ),
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
                              Row(
                                children: [
                                  Text(
                                    l10n.availableTimeSlotsTitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: CivicTheme.textPrimary,
                                    ),
                                  ),
                                  if (isLoadingSlots) ...[
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.slotsLoadingLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: CivicTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (!isLoadingSlots && currentSlots.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: CivicTheme.warningSoft,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: CivicTheme.warning),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: Color(0xFF8A5800), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.noSlotsAvailableNotice,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B4500),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: currentSlots.map((slot) {
                                  final isSelected =
                                      selectedSlotTime == slot.slotTime &&
                                      slot.available;
                              
                                  return Semantics(
                                    label: "${slot.slotTime}, ${_getSlotStatusLabel(slot, l10n)}",
                                    enabled: slot.available,
                                    button: true,
                                    child: InkWell(
                                      onTap: () {
                                        if (slot.available) {
                                          setSheetState(() {
                                            selectedSlotTime = slot.slotTime;
                                            localNotice = null;
                                          });
                                        } else {
                                          setSheetState(() {
                                            localNotice = _getSlotErrorMessage(slot, l10n);
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 160,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !slot.available
                                              ? Colors.grey.shade100
                                              : (isSelected
                                                    ? CivicTheme.primarySoft
                                                    : CivicTheme.surface),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: !slot.available
                                                ? Colors.grey.shade300
                                                : (isSelected
                                                      ? CivicTheme.primary
                                                      : CivicTheme.border),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              slot.slotTime,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: !slot.available
                                                    ? Colors.grey.shade500
                                                    : (isSelected
                                                          ? CivicTheme.primary
                                                          : CivicTheme
                                                                .textPrimary),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: _buildSlotStatusBadge(
                                                    slot,
                                                    l10n,
                                                    isSelected,
                                                  ),
                                                ),
                                                if (isSelected) ...[
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.check_circle,
                                                    size: 16,
                                                    color: CivicTheme.primary,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (localNotice != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: CivicTheme.errorSoft,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: CivicTheme.error.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: CivicTheme.error,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          localNotice!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: CivicTheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),

                              // Party Size Selector (Max 4 People: primary + up to 3 accompanying)
                              Text(
                                l10n.peopleCountPrompt,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: CivicTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [1, 2, 3, 4].map((count) {
                                  final isSelected = familyCount == count;
                                  return ChoiceChip(
                                    label: Text(
                                      count == 1
                                          ? l10n.onePerson
                                          : l10n.multiplePeople(count),
                                    ),
                                    selected: isSelected,
                                    selectedColor: CivicTheme.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : CivicTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setSheetState(
                                          () {
                                            familyCount = count;
                                            localNotice = null;
                                          },
                                        );
                                        fetchSlotsForDateAndParty();
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.queueSlotsReservedCount(familyCount),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: familyCount > 1
                                      ? CivicTheme.primary
                                      : CivicTheme.textSecondary,
                                ),
                              ),
                              if (familyCount > 1) ...[
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: CivicTheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: CivicTheme.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Section Header
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.group_outlined,
                                            color: CivicTheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l10n.accompanyingPersonsSectionTitle,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: CivicTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Single Counter Policy Notice
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: CivicTheme.warningSoft,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: CivicTheme.warning.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.info_outline,
                                              color: Color(0xFF8A5800),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                l10n.sameCounterOnlyNotice,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF6B4500),
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Accompanying person details list
                                      ...List.generate(familyCount - 1, (k) {
                                        final personNumber = k + 2;
                                        final hasOtherCounterError =
                                            _safeAccompanyingReasonKeys[k] == 'other_counter';
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: CivicTheme.canvas,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: hasOtherCounterError
                                                  ? CivicTheme.error
                                                  : CivicTheme.border,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Wrap(
                                                alignment: WrapAlignment.spaceBetween,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  Text(
                                                    l10n.personIndexLabel(personNumber),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: CivicTheme.primary,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: CivicTheme.primarySoft,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${l10n.allottedSlotTimeLabel}: ${_calculateStaggeredSlotTime(selectedSlotTime, k + 1)}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: CivicTheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Full Name
                                              TextField(
                                                key: Key('accompanying_name_$k'),
                                                controller: _accompanyingNameControllers[k],
                                                decoration: InputDecoration(
                                                  hintText: l10n.accompanyingPersonNameHint,
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                                                ),
                                                onChanged: (_) {
                                                  setSheetState(() {});
                                                },
                                              ),
                                              const SizedBox(height: 10),
                                              // Reason for Co-Attendance Dropdown
                                              DropdownButtonFormField<String>(
                                                key: Key('accompanying_reason_$k'),
                                                isExpanded: true,
                                                initialValue: _safeAccompanyingReasonKeys[k],
                                                decoration: InputDecoration(
                                                  labelText: l10n.coAttendanceReasonLabel,
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  prefixIcon: const Icon(
                                                    Icons.assignment_ind_outlined,
                                                    size: 18,
                                                  ),
                                                ),
                                                hint: Text(
                                                  l10n.selectCoAttendanceReasonPrompt,
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                items: [
                                                  DropdownMenuItem(
                                                    value: 'joint_applicant',
                                                    child: Text(
                                                      l10n.reasonJointApplicant,
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'assistance',
                                                    child: Text(
                                                      l10n.reasonAssistance,
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'guardian',
                                                    child: Text(
                                                      l10n.reasonGuardian,
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'witness',
                                                    child: Text(
                                                      l10n.reasonWitnessSignatory,
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'family_verification',
                                                    child: Text(
                                                      l10n.reasonFamilyVerification,
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'other_counter',
                                                    child: Text(
                                                      l10n.reasonOtherCounterWork,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: CivicTheme.error,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (val) {
                                                  setSheetState(() {
                                                    _safeAccompanyingReasonKeys[k] = val;
                                                  });
                                                },
                                              ),
                                              if (hasOtherCounterError) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: CivicTheme.errorSoft,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Icon(
                                                        Icons.error_outline,
                                                        color: CivicTheme.error,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          l10n.invalidCounterReasonError,
                                                          style: const TextStyle(
                                                            color: CivicTheme.error,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Builder(
                        builder: (ctx) {
                          final accompanyingError =
                              _getAccompanyingValidationError(familyCount, l10n);
                          final dateExceedsLimit = diffDays > 15;
                          final dateError = dateExceedsLimit ? l10n.dateExceeds15DaysError : null;
                          final selectedSlotItem = currentSlots.where((s) => s.slotTime == selectedSlotTime).firstOrNull;
                          final isSlotAvailable = selectedSlotItem?.available ?? true;
                          final slotUnavailableError = !isSlotAvailable ? l10n.slotNoLongerAvailable : null;
                          final counterUnavailableError = (_service != null && !_service!.isCounterOpen)
                              ? (_service!.isCounterClosed ? l10n.counterClosedNotice : l10n.counterOnBreakNotice)
                              : null;
                          final activeError = localNotice ?? accompanyingError ?? dateError ?? slotUnavailableError ?? counterUnavailableError;
                          final canConfirm = activeError == null;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (activeError != null) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: CivicTheme.errorSoft,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: CivicTheme.error.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: CivicTheme.error,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          activeError,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: CivicTheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle, size: 22),
                                label: Text(
                                  isCustomSlot
                                      ? l10n.confirmAppointmentHigher
                                      : l10n.confirmAppointmentStandard,
                                ),
                                onPressed: canConfirm
                                    ? () {
                                        Navigator.of(sheetContext).pop();
                                        setState(() {
                                          _selectedDayIndex = diffDays;
                                          _selectedSlotTime = selectedSlotTime;
                                          _familyCount = familyCount;
                                        });
                                        _handleBook();
                                      }
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.help_outline, size: 15),
                          label: Text(
                            l10n.viewAppointmentRulesAction,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: CivicTheme.primary,
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            try {
                              context.push('/policies');
                            } catch (_) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PoliciesScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatFullDate(
    DateTime date,
    int diffDays,
    String currentLang,
    AppLocalizations l10n,
  ) {
    final enWeekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final guWeekdays = [
      'સોમવાર',
      'મંગળવાર',
      'બુધવાર',
      'ગુરૂવાર',
      'શુક્રવાર',
      'શનિવાર',
      'રવિવાર',
    ];
    final hiWeekdays = [
      'सोमवार',
      'मंगलवार',
      'बुधवार',
      'गुरुवार',
      'शुक्रवार',
      'शनिवार',
      'रविवार',
    ];

    final enMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final guMonths = [
      'જાન્યુ',
      'ફેબ્રુ',
      'માર્ચ',
      'એપ્રિલ',
      'મે',
      'જૂન',
      'જુલાઈ',
      'ઓગસ્ટ',
      'સપ્ટે',
      'ઓક્ટો',
      'નવે',
      'ડિસે',
    ];
    final hiMonths = [
      'जनवरी',
      'फ़रवरी',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अगस्त',
      'सितंबर',
      'अक्टूबर',
      'नवंबर',
      'दिसंबर',
    ];

    final weekdays = currentLang == 'gu'
        ? guWeekdays
        : (currentLang == 'hi' ? hiWeekdays : enWeekdays);
    final months = currentLang == 'gu'
        ? guMonths
        : (currentLang == 'hi' ? hiMonths : enMonths);

    final String relative;
    if (diffDays == 0) {
      relative = ' (${l10n.todayLabel})';
    } else if (diffDays == 1) {
      relative = ' (${l10n.tomorrowLabel})';
    } else {
      relative = currentLang == 'gu'
          ? ' ($diffDays દિવસમાં)'
          : (currentLang == 'hi'
                ? ' ($diffDays दिनों में)'
                : ' (In $diffDays Days)');
    }
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
