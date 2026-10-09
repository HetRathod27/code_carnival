import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class PolicySectionModel {
  final String id;
  final String titleKey;
  final IconData icon;
  final List<String> bodyKeys;

  const PolicySectionModel({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.bodyKeys,
  });
}

class PolicyCategoryModel {
  final String id;
  final String titleKey;
  final IconData icon;
  final List<PolicySectionModel> sections;

  const PolicyCategoryModel({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.sections,
  });
}

const List<PolicyCategoryModel> policyCategories = [
  // Category 1: Booking Rules
  PolicyCategoryModel(
    id: 'booking_rules',
    titleKey: 'categoryBookingRules',
    icon: Icons.calendar_month_outlined,
    sections: [
      PolicySectionModel(
        id: 'how_appointments_work',
        titleKey: 'secHowAppointmentsWorkTitle',
        icon: Icons.schedule_outlined,
        bodyKeys: [
          'secHowAppointmentsWorkP1',
          'secHowAppointmentsWorkP2',
          'secHowAppointmentsWorkP3',
          'secHowAppointmentsWorkP4',
        ],
      ),
      PolicySectionModel(
        id: 'appointment_confirmation',
        titleKey: 'secAppointmentConfirmationTitle',
        icon: Icons.confirmation_number_outlined,
        bodyKeys: [
          'secAppointmentConfirmationP1',
          'secAppointmentConfirmationP2',
        ],
      ),
      PolicySectionModel(
        id: 'required_documents',
        titleKey: 'secRequiredDocumentsTitle',
        icon: Icons.fact_check_outlined,
        bodyKeys: [
          'secRequiredDocumentsP1',
          'secRequiredDocumentsP2',
          'secRequiredDocumentsP3',
        ],
      ),
      PolicySectionModel(
        id: 'slot_fees',
        titleKey: 'secSlotFeesTitle',
        icon: Icons.payments_outlined,
        bodyKeys: [
          'secSlotFeesP1',
          'secSlotFeesP2',
          'secSlotFeesP3',
        ],
      ),
      PolicySectionModel(
        id: 'advance_deadlines',
        titleKey: 'secAdvanceDeadlinesTitle',
        icon: Icons.timer_outlined,
        bodyKeys: [
          'secAdvanceDeadlinesP1',
          'secAdvanceDeadlinesP2',
        ],
      ),
    ],
  ),

  // Category 2: Arrival & Service Delivery
  PolicyCategoryModel(
    id: 'arrival_service',
    titleKey: 'categoryArrivalService',
    icon: Icons.business_outlined,
    sections: [
      PolicySectionModel(
        id: 'arrival_checkin',
        titleKey: 'secArrivalCheckinTitle',
        icon: Icons.qr_code_scanner_outlined,
        bodyKeys: [
          'secArrivalCheckinP1',
          'secArrivalCheckinP2',
          'secArrivalCheckinP3',
        ],
      ),
      PolicySectionModel(
        id: 'on_my_way',
        titleKey: 'secOnMyWayTitle',
        icon: Icons.directions_walk_outlined,
        bodyKeys: [
          'secOnMyWayP1',
          'secOnMyWayP2',
          'secOnMyWayP3',
        ],
      ),
      PolicySectionModel(
        id: 'if_late',
        titleKey: 'secIfLateTitle',
        icon: Icons.alarm_off_outlined,
        bodyKeys: [
          'secIfLateP1',
          'secIfLateP2',
          'secIfLateP3',
        ],
      ),
      PolicySectionModel(
        id: 'no_show',
        titleKey: 'secNoShowTitle',
        icon: Icons.person_off_outlined,
        bodyKeys: [
          'secNoShowP1',
          'secNoShowP2',
        ],
      ),
      PolicySectionModel(
        id: 'counter_token_verification',
        titleKey: 'secCounterVerificationTitle',
        icon: Icons.shield_outlined,
        bodyKeys: [
          'secCounterVerificationP1',
          'secCounterVerificationP2',
          'secCounterVerificationP3',
        ],
      ),
      PolicySectionModel(
        id: 'service_completion',
        titleKey: 'secServiceCompletionTitle',
        icon: Icons.verified_outlined,
        bodyKeys: [
          'secServiceCompletionP1',
          'secServiceCompletionP2',
        ],
      ),
      PolicySectionModel(
        id: 'rating_feedback',
        titleKey: 'secRatingFeedbackTitle',
        icon: Icons.rate_review_outlined,
        bodyKeys: [
          'secRatingFeedbackP1',
          'secRatingFeedbackP2',
        ],
      ),
    ],
  ),

  // Category 3: Problems & What To Do
  PolicyCategoryModel(
    id: 'changes_delays',
    titleKey: 'categoryChangesDelays',
    icon: Icons.warning_amber_rounded,
    sections: [
      PolicySectionModel(
        id: 'cancellation_rules',
        titleKey: 'secCancellationRulesTitle',
        icon: Icons.cancel_outlined,
        bodyKeys: [
          'secCancellationRulesP1',
          'secCancellationRulesP2',
          'secCancellationRulesP3',
        ],
      ),
      PolicySectionModel(
        id: 'rescheduling_policy',
        titleKey: 'secReschedulingPolicyTitle',
        icon: Icons.event_repeat_outlined,
        bodyKeys: [
          'secReschedulingPolicyP1',
          'secReschedulingPolicyP2',
        ],
      ),
      PolicySectionModel(
        id: 'office_delays',
        titleKey: 'secOfficeDelaysTitle',
        icon: Icons.hourglass_empty_outlined,
        bodyKeys: [
          'secOfficeDelaysP1',
          'secOfficeDelaysP2',
        ],
      ),
      PolicySectionModel(
        id: 'office_closures',
        titleKey: 'secOfficeClosuresTitle',
        icon: Icons.door_back_door_outlined,
        bodyKeys: [
          'secOfficeClosuresP1',
          'secOfficeClosuresP2',
        ],
      ),
      PolicySectionModel(
        id: 'server_failures',
        titleKey: 'secServerFailuresTitle',
        icon: Icons.cloud_off_outlined,
        bodyKeys: [
          'secServerFailuresP1',
          'secServerFailuresP2',
        ],
      ),
      PolicySectionModel(
        id: 'troubleshooting',
        titleKey: 'secTroubleshootingTitle',
        icon: Icons.live_help_outlined,
        bodyKeys: [
          'secTroubleshootingP1',
          'secTroubleshootingP2',
          'secTroubleshootingP3',
          'secTroubleshootingP4',
          'secTroubleshootingP5',
          'secTroubleshootingP6',
        ],
      ),
    ],
  ),

  // Category 4: Special Categories & System Rules
  PolicyCategoryModel(
    id: 'special_rules',
    titleKey: 'categorySpecialRules',
    icon: Icons.groups_outlined,
    sections: [
      PolicySectionModel(
        id: 'family_group',
        titleKey: 'secFamilyGroupTitle',
        icon: Icons.group_outlined,
        bodyKeys: [
          'secFamilyGroupP1',
          'secFamilyGroupP2',
          'secFamilyGroupP3',
        ],
      ),
      PolicySectionModel(
        id: 'multiple_services',
        titleKey: 'secMultipleServicesTitle',
        icon: Icons.format_list_bulleted_outlined,
        bodyKeys: [
          'secMultipleServicesP1',
          'secMultipleServicesP2',
        ],
      ),
      PolicySectionModel(
        id: 'duplicate_booking',
        titleKey: 'secDuplicateBookingTitle',
        icon: Icons.block_outlined,
        bodyKeys: [
          'secDuplicateBookingP1',
          'secDuplicateBookingP2',
        ],
      ),
      PolicySectionModel(
        id: 'physical_walkins',
        titleKey: 'secPhysicalWalkinsTitle',
        icon: Icons.print_outlined,
        bodyKeys: [
          'secPhysicalWalkinsP1',
          'secPhysicalWalkinsP2',
          'secPhysicalWalkinsP3',
        ],
      ),
      PolicySectionModel(
        id: 'priority_citizens',
        titleKey: 'secPriorityCitizensTitle',
        icon: Icons.accessible_forward_outlined,
        bodyKeys: [
          'secPriorityCitizensP1',
          'secPriorityCitizensP2',
        ],
      ),
      PolicySectionModel(
        id: 'privacy_display',
        titleKey: 'secPrivacyDisplayTitle',
        icon: Icons.security_outlined,
        bodyKeys: [
          'secPrivacyDisplayP1',
          'secPrivacyDisplayP2',
        ],
      ),
    ],
  ),
];

String getLocalizedPolicyText(AppLocalizations l10n, String key) {
  switch (key) {
    // Header & Meta
    case 'helpAndRulesTitle':
      return l10n.helpAndRulesTitle;
    case 'helpAndRulesSubtitle':
      return l10n.helpAndRulesSubtitle;
    case 'helpAndRulesAction':
      return l10n.helpAndRulesAction;
    case 'helpAndPoliciesSection':
      return l10n.helpAndPoliciesSection;
    case 'viewAppointmentRulesAction':
      return l10n.viewAppointmentRulesAction;
    case 'importantCivicNoticeTitle':
      return l10n.importantCivicNoticeTitle;
    case 'importantCivicNoticeBody':
      return l10n.importantCivicNoticeBody;

    // Categories
    case 'categoryBookingRules':
      return l10n.categoryBookingRules;
    case 'categoryArrivalService':
      return l10n.categoryArrivalService;
    case 'categoryChangesDelays':
      return l10n.categoryChangesDelays;
    case 'categorySpecialRules':
      return l10n.categorySpecialRules;

    // Category 1: Booking Rules
    case 'secHowAppointmentsWorkTitle':
      return l10n.secHowAppointmentsWorkTitle;
    case 'secHowAppointmentsWorkP1':
      return l10n.secHowAppointmentsWorkP1;
    case 'secHowAppointmentsWorkP2':
      return l10n.secHowAppointmentsWorkP2;
    case 'secHowAppointmentsWorkP3':
      return l10n.secHowAppointmentsWorkP3;
    case 'secHowAppointmentsWorkP4':
      return l10n.secHowAppointmentsWorkP4;

    case 'secAppointmentConfirmationTitle':
      return l10n.secAppointmentConfirmationTitle;
    case 'secAppointmentConfirmationP1':
      return l10n.secAppointmentConfirmationP1;
    case 'secAppointmentConfirmationP2':
      return l10n.secAppointmentConfirmationP2;

    case 'secRequiredDocumentsTitle':
      return l10n.secRequiredDocumentsTitle;
    case 'secRequiredDocumentsP1':
      return l10n.secRequiredDocumentsP1;
    case 'secRequiredDocumentsP2':
      return l10n.secRequiredDocumentsP2;
    case 'secRequiredDocumentsP3':
      return l10n.secRequiredDocumentsP3;

    case 'secSlotFeesTitle':
      return l10n.secSlotFeesTitle;
    case 'secSlotFeesP1':
      return l10n.secSlotFeesP1;
    case 'secSlotFeesP2':
      return l10n.secSlotFeesP2;
    case 'secSlotFeesP3':
      return l10n.secSlotFeesP3;

    case 'secAdvanceDeadlinesTitle':
      return l10n.secAdvanceDeadlinesTitle;
    case 'secAdvanceDeadlinesP1':
      return l10n.secAdvanceDeadlinesP1;
    case 'secAdvanceDeadlinesP2':
      return l10n.secAdvanceDeadlinesP2;

    // Category 2: Arrival & Service Delivery
    case 'secArrivalCheckinTitle':
      return l10n.secArrivalCheckinTitle;
    case 'secArrivalCheckinP1':
      return l10n.secArrivalCheckinP1;
    case 'secArrivalCheckinP2':
      return l10n.secArrivalCheckinP2;
    case 'secArrivalCheckinP3':
      return l10n.secArrivalCheckinP3;

    case 'secOnMyWayTitle':
      return l10n.secOnMyWayTitle;
    case 'secOnMyWayP1':
      return l10n.secOnMyWayP1;
    case 'secOnMyWayP2':
      return l10n.secOnMyWayP2;
    case 'secOnMyWayP3':
      return l10n.secOnMyWayP3;

    case 'secIfLateTitle':
      return l10n.secIfLateTitle;
    case 'secIfLateP1':
      return l10n.secIfLateP1;
    case 'secIfLateP2':
      return l10n.secIfLateP2;
    case 'secIfLateP3':
      return l10n.secIfLateP3;

    case 'secNoShowTitle':
      return l10n.secNoShowTitle;
    case 'secNoShowP1':
      return l10n.secNoShowP1;
    case 'secNoShowP2':
      return l10n.secNoShowP2;

    case 'secCounterVerificationTitle':
      return l10n.secCounterVerificationTitle;
    case 'secCounterVerificationP1':
      return l10n.secCounterVerificationP1;
    case 'secCounterVerificationP2':
      return l10n.secCounterVerificationP2;
    case 'secCounterVerificationP3':
      return l10n.secCounterVerificationP3;

    case 'secServiceCompletionTitle':
      return l10n.secServiceCompletionTitle;
    case 'secServiceCompletionP1':
      return l10n.secServiceCompletionP1;
    case 'secServiceCompletionP2':
      return l10n.secServiceCompletionP2;

    case 'secRatingFeedbackTitle':
      return l10n.secRatingFeedbackTitle;
    case 'secRatingFeedbackP1':
      return l10n.secRatingFeedbackP1;
    case 'secRatingFeedbackP2':
      return l10n.secRatingFeedbackP2;

    // Category 3: Problems & What To Do
    case 'secCancellationRulesTitle':
      return l10n.secCancellationRulesTitle;
    case 'secCancellationRulesP1':
      return l10n.secCancellationRulesP1;
    case 'secCancellationRulesP2':
      return l10n.secCancellationRulesP2;
    case 'secCancellationRulesP3':
      return l10n.secCancellationRulesP3;

    case 'secReschedulingPolicyTitle':
      return l10n.secReschedulingPolicyTitle;
    case 'secReschedulingPolicyP1':
      return l10n.secReschedulingPolicyP1;
    case 'secReschedulingPolicyP2':
      return l10n.secReschedulingPolicyP2;

    case 'secOfficeDelaysTitle':
      return l10n.secOfficeDelaysTitle;
    case 'secOfficeDelaysP1':
      return l10n.secOfficeDelaysP1;
    case 'secOfficeDelaysP2':
      return l10n.secOfficeDelaysP2;

    case 'secOfficeClosuresTitle':
      return l10n.secOfficeClosuresTitle;
    case 'secOfficeClosuresP1':
      return l10n.secOfficeClosuresP1;
    case 'secOfficeClosuresP2':
      return l10n.secOfficeClosuresP2;

    case 'secServerFailuresTitle':
      return l10n.secServerFailuresTitle;
    case 'secServerFailuresP1':
      return l10n.secServerFailuresP1;
    case 'secServerFailuresP2':
      return l10n.secServerFailuresP2;

    case 'secTroubleshootingTitle':
      return l10n.secTroubleshootingTitle;
    case 'secTroubleshootingP1':
      return l10n.secTroubleshootingP1;
    case 'secTroubleshootingP2':
      return l10n.secTroubleshootingP2;
    case 'secTroubleshootingP3':
      return l10n.secTroubleshootingP3;
    case 'secTroubleshootingP4':
      return l10n.secTroubleshootingP4;
    case 'secTroubleshootingP5':
      return l10n.secTroubleshootingP5;
    case 'secTroubleshootingP6':
      return l10n.secTroubleshootingP6;

    // Category 4: Special Categories & System Rules
    case 'secFamilyGroupTitle':
      return l10n.secFamilyGroupTitle;
    case 'secFamilyGroupP1':
      return l10n.secFamilyGroupP1;
    case 'secFamilyGroupP2':
      return l10n.secFamilyGroupP2;
    case 'secFamilyGroupP3':
      return l10n.secFamilyGroupP3;

    case 'secMultipleServicesTitle':
      return l10n.secMultipleServicesTitle;
    case 'secMultipleServicesP1':
      return l10n.secMultipleServicesP1;
    case 'secMultipleServicesP2':
      return l10n.secMultipleServicesP2;

    case 'secDuplicateBookingTitle':
      return l10n.secDuplicateBookingTitle;
    case 'secDuplicateBookingP1':
      return l10n.secDuplicateBookingP1;
    case 'secDuplicateBookingP2':
      return l10n.secDuplicateBookingP2;

    case 'secPhysicalWalkinsTitle':
      return l10n.secPhysicalWalkinsTitle;
    case 'secPhysicalWalkinsP1':
      return l10n.secPhysicalWalkinsP1;
    case 'secPhysicalWalkinsP2':
      return l10n.secPhysicalWalkinsP2;
    case 'secPhysicalWalkinsP3':
      return l10n.secPhysicalWalkinsP3;

    case 'secPriorityCitizensTitle':
      return l10n.secPriorityCitizensTitle;
    case 'secPriorityCitizensP1':
      return l10n.secPriorityCitizensP1;
    case 'secPriorityCitizensP2':
      return l10n.secPriorityCitizensP2;

    case 'secPrivacyDisplayTitle':
      return l10n.secPrivacyDisplayTitle;
    case 'secPrivacyDisplayP1':
      return l10n.secPrivacyDisplayP1;
    case 'secPrivacyDisplayP2':
      return l10n.secPrivacyDisplayP2;

    // Legacy fallbacks
    case 'rulesAndPoliciesTitle':
      return l10n.helpAndRulesTitle;
    case 'rulesAndPoliciesSubtitle':
      return l10n.helpAndRulesSubtitle;
    case 'policyFooterHeading':
      return l10n.policyFooterHeading;
    case 'policyFooterVersion':
      return l10n.policyFooterVersion;
    case 'policyTapToExpand':
      return l10n.policyTapToExpand;
    case 'policyTapToCollapse':
      return l10n.policyTapToCollapse;

    default:
      return key;
  }
}
