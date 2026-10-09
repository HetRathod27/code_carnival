// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'QueueLess';

  @override
  String get welcomeTitle => 'Government Service Appointments';

  @override
  String get welcomeSubtitle =>
      'Book fixed appointments, track your turn live, and avoid waiting in lines.';

  @override
  String get selectLanguage => 'Select Your Language';

  @override
  String get english => 'English';

  @override
  String get gujarati => 'ગુજરાતી (Gujarati)';

  @override
  String get hindi => 'हिन्दी (Hindi)';

  @override
  String get continueButton => 'Continue';

  @override
  String get loginTitle => 'Sign In with Phone';

  @override
  String get loginSubtitle =>
      'Enter your mobile number to receive a verification OTP.';

  @override
  String get phoneNumber => 'Mobile Number';

  @override
  String get enterOtp => 'Enter 6-Digit OTP';

  @override
  String get sendOtp => 'Send Verification Code';

  @override
  String get verifyOtp => 'Verify & Enter';

  @override
  String get browseOffices => 'Select Civic Centre';

  @override
  String get browseServices => 'Select Service';

  @override
  String get requiredDocuments => 'Required Documents';

  @override
  String get confirmDocumentsPrompt =>
      'I confirm that I have all required original documents ready for this visit.';

  @override
  String get checkAllDocsFirstNotice =>
      'Please tick every required document above first.';

  @override
  String docsVerifiedProgress(int checked, int total) {
    return '$checked of $total checked';
  }

  @override
  String get bookSlot => 'Book Fixed Appointment';

  @override
  String get familyCount => 'Number of People Coming';

  @override
  String get myToken => 'My Active Token';

  @override
  String get appointmentTime => 'Appointment Time';

  @override
  String get estimatedTurn => 'Estimated Turn';

  @override
  String get nowServing => 'Now Serving';

  @override
  String get waitingAhead => 'Waiting Ahead';

  @override
  String get checkInQr => 'Presence Check-In';

  @override
  String get scanEntranceQr => 'Scan Entrance QR to Confirm Arrival';

  @override
  String get cancelAppointment => 'Cancel Appointment';

  @override
  String get confirmCompletion => 'Confirm Service Completion';

  @override
  String get leaveNowAlert => 'Leave Now: Your turn is approaching!';

  @override
  String get doubleConfirmationPrompt =>
      'Officer has marked service completed. Please confirm below:';

  @override
  String get serviceCompleted => 'Service Successfully Completed';

  @override
  String get officesTitle => 'Civic Centres';

  @override
  String get servicesTitle => 'Available Services';

  @override
  String get selectOfficePrompt =>
      'Choose your nearest municipal or ward office.';

  @override
  String get selectServicePrompt =>
      'Select the civic service you need assistance with.';

  @override
  String get noOfficesFound => 'No civic centres currently available.';

  @override
  String get noServicesFound => 'No services available at this centre.';

  @override
  String get documentChecklistTitle => 'Required Document Checklist';

  @override
  String get documentChecklistSubtitle =>
      'Please ensure you have originals and copies of the following documents before visiting the office:';

  @override
  String get categorySelectionTitle => 'Booking Category';

  @override
  String get categoryNormalLabel => 'General / Normal';

  @override
  String get categoryPriorityLabel => 'Priority Access';

  @override
  String get categoryPriorityNotice =>
      'Reserved for senior citizens (60+), pregnant women, and persons with disabilities. Valid ID/proof required upon arrival.';

  @override
  String get beneficiaryNameLabel => 'Beneficiary Name (Optional)';

  @override
  String get beneficiaryNameHint => 'Name of the person being served';

  @override
  String get bookAppointmentAction => 'Book Fixed Appointment';

  @override
  String get bookingConfirmationTitle => 'Appointment Confirmed!';

  @override
  String get bookingSuccessMessage =>
      'Your appointment has been registered. Arrive on time to ensure prompt service.';

  @override
  String get viewTokenAction => 'View My Token';

  @override
  String get onlineAlternativeNotice =>
      'This service is also available online! You can save a visit by using the official online portal.';

  @override
  String get openOnlineLink => 'Open Online Portal';

  @override
  String get avgServiceDuration => 'Average Service Duration';

  @override
  String get currentQueueWait => 'Current Queue Wait';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get retryAction => 'Retry';

  @override
  String get officeHoursLabel => 'Operating Hours';

  @override
  String get onMyWayAction => 'I\'m on My Way (+5 min)';

  @override
  String get onMyWaySuccess => 'Extra 5 minutes grace period granted!';

  @override
  String get onMyWayClaimed => 'Extension Claimed';

  @override
  String get presenceVerified => 'Arrival Verified at Centre';

  @override
  String get enterQrCodePrompt => 'Enter or Scan Entrance QR Code';

  @override
  String get confirmCancelPrompt =>
      'Are you sure you want to cancel this appointment?';

  @override
  String get cancelReasonLabel => 'Reason for cancellation (optional)';

  @override
  String get etaRangePrefix => 'Estimated Turn Window:';

  @override
  String get nowServingAt => 'Now Serving At:';

  @override
  String get chooseDateTimeSlot => 'Choose an Available Appointment Slot';

  @override
  String get chooseAvailableSlotInstruction =>
      'Select an available fixed appointment slot from the schedule below.';

  @override
  String get selectedDateLabel => 'Selected Date';

  @override
  String get openCalendarAction => 'Open Calendar';

  @override
  String get quickSelectionTitle => 'Quick Selection';

  @override
  String get todayLabel => 'Today';

  @override
  String get tomorrowLabel => 'Tomorrow';

  @override
  String get in2DaysLabel => 'In 2 Days';

  @override
  String get in3DaysLabel => 'In 3 Days';

  @override
  String get within2DaysFeeFree => 'Within 2 Days • ₹20 Fee';

  @override
  String get customDateFee50 => 'Custom Date • ₹50 Fee';

  @override
  String get normalSlotTitle =>
      'Normal Slot (Within 2 Days) • ₹20 Standard Fee';

  @override
  String get customSlotTitle => 'Custom Future Slot • Higher Fee (₹50)';

  @override
  String get statutoryDisclosure =>
      'Statutory Disclosure (Spec Section 6.3): A custom slot fee does not protect against official department emergency closures, gazetted holidays, or government server delay.';

  @override
  String get standardNearTermNotice =>
      'Standard near-term booking within 2 days carries a ₹20 booking fee.';

  @override
  String get availableTimeSlotsTitle => 'Available Time Slots';

  @override
  String get slotsFullWarning =>
      'Slots are full for this time! Please select another available slot or another day. Booking any available normal slot within 2 days carries a ₹20 standard fee.';

  @override
  String get slotsFullBadge => 'Slots Full';

  @override
  String get availableBadge => 'Available';

  @override
  String get peopleCountPrompt =>
      'How many people are coming with you? (Spec Section 7.2)';

  @override
  String get confirmAppointmentStandard =>
      'Confirm Appointment • Standard Fee: ₹20';

  @override
  String get confirmAppointmentHigher =>
      'Confirm Appointment • Higher Fee: ₹50';

  @override
  String get applicantDetailsTitle => 'Applicant Details';

  @override
  String get dateSummaryLabel => 'Date:';

  @override
  String get slotTimeSummaryLabel => 'Slot Time:';

  @override
  String get partySizeSummaryLabel => 'Party Size:';

  @override
  String get feeTierSummaryLabel => 'Fee Tier:';

  @override
  String get standardFreeTier => 'Standard Slot (₹20)';

  @override
  String get customPaidTier => 'Custom Advance Slot (₹50)';

  @override
  String get onePerson => '1 Person';

  @override
  String multiplePeople(Object count) {
    return '$count People';
  }

  @override
  String get signInTitle => 'QueueLess Sign In';

  @override
  String get enterMobileNumber => 'Enter Mobile Number';

  @override
  String get invalidPhoneError => 'Please enter a valid mobile number';

  @override
  String get invalidOtpError => 'Please enter 6-digit OTP';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get sendOtpAction => 'Get Verification Code';

  @override
  String get verifyOtpAction => 'Verify OTP & Enter';

  @override
  String get otpLabel => '6-Digit OTP';

  @override
  String get activeAppointmentBanner => 'Active Appointment in Progress';

  @override
  String tapToViewEta(String code) {
    return 'Token: $code • Tap to view live ETA';
  }

  @override
  String get priorityAllowedBadge => '⭐ Priority Allowed';

  @override
  String get seniorCitizenCategory => 'Senior Citizen (60+ years)';

  @override
  String get pregnantCategory => 'Pregnant / Nursing Mother';

  @override
  String get disabilityCategory => 'Person with Disability (PwD)';

  @override
  String get medicalCategory => 'Medical Urgency / Health';

  @override
  String get eligibilityCategoryLabel => 'Eligibility Category';

  @override
  String get signOutTooltip => 'Sign Out';

  @override
  String get keepAppointmentAction => 'Keep Appointment';

  @override
  String get yesCancelAction => 'Yes, Cancel';

  @override
  String get cancelSuccessMessage => 'Appointment successfully cancelled';

  @override
  String get priorityBadge => '⭐ Priority';

  @override
  String get notCheckedInStatus => 'Not Yet Checked In';

  @override
  String get calculatingEta => 'Calculating…';

  @override
  String get noActiveAppointment => 'No Active Appointment';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get verifyArrivalAction => 'Verify Arrival';

  @override
  String get qrCodeInstruction =>
      'Show this QR code to the entrance officer or counter scanner to verify your arrival.';

  @override
  String get manualVerificationCodePrompt => 'Token Verification Code';

  @override
  String get qrFallbackOfficerNotice =>
      'Share this code with the officer if the QR scanner faces any issue.';

  @override
  String get appointmentConfirmedCardTitle => 'Appointment Confirmed';

  @override
  String get appointmentFutureNotice =>
      'Your appointment is confirmed for an upcoming date. Live queue status will activate on the day of your appointment when the office opens.';

  @override
  String get appointmentScheduledFor => 'Scheduled Date & Time';

  @override
  String get serviceLabel => 'Service';

  @override
  String get civicCentreLabel => 'Civic Centre';

  @override
  String get tokenLabel => 'Token Code';

  @override
  String get partySizeLabel => 'Party / Group Size';

  @override
  String get feeLabel => 'Applicable Fee';

  @override
  String get feeDemoNotice => 'Demo fee only • No payment gateway connected';

  @override
  String get feeFreeNotice => 'Standard civic appointment • ₹20 Fee';

  @override
  String get liveQueueActiveNotice => 'Active Office Queue Tracking';

  @override
  String get officeDelayAlert =>
      'Office is currently experiencing a service delay. Your appointment time remains unchanged, but service may take longer than expected.';

  @override
  String get cancelNotAllowedNotice =>
      'Cancellation cutoff has passed. This appointment cannot be cancelled online.';

  @override
  String get searchServicesPlaceholder => 'Search services';

  @override
  String get searchServicesTooltip => 'Search services';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String centresOfferService(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count centres offer this service',
      one: '1 centre offers this service',
    );
    return '$_temp0';
  }

  @override
  String serviceAvailableNotice(String serviceName) {
    return '→ $serviceName available';
  }

  @override
  String get noCentresOfferService =>
      'No civic centre in this city offers this service.';

  @override
  String get clearSearchAction => 'Clear Search';

  @override
  String get rulesAndPoliciesTitle => 'Rules & Policies';

  @override
  String get rulesAndPoliciesSubtitle =>
      'What to do in different situations while using QueueLess';

  @override
  String get rulesAndPoliciesAction => 'Rules & Policies';

  @override
  String get viewAppointmentPoliciesAction => 'View Appointment Policies';

  @override
  String get policyFooterHeading => 'QueueLess Appointment & Service Policies';

  @override
  String get policyFooterVersion =>
      'Official Civic System v1.1.0 • Gujarat e-Gov';

  @override
  String get policyTapToExpand => 'Tap to view rules';

  @override
  String get policyTapToCollapse => 'Tap to collapse';

  @override
  String get categoryBooking => '1. Booking an Appointment';

  @override
  String get categoryOnTheDay => '2. On the Day of Visit';

  @override
  String get categoryChangesProblems => '3. Changes & Problem Handling';

  @override
  String get categorySpecialCases => '4. Special Categories & Walk-ins';

  @override
  String get policyBookingFlowTitle =>
      'Booking an Appointment & Document Checklist';

  @override
  String get policyBookingFlowP1 =>
      'To schedule an appointment, first select your city, your nearest civic centre, and the required municipal service.';

  @override
  String get policyBookingFlowP2 =>
      'Review the mandatory document checklist before booking. You must confirm that all required original documents are ready before the booking button is enabled.';

  @override
  String get policyBookingFlowP3 =>
      'Choose your preferred available date (Today, Tomorrow, or an upcoming working day) and a fixed time slot.';

  @override
  String get policyBookingFlowP4 =>
      'Select the number of people coming with the booking (1 to 5+). Your appointment is strictly locked to the chosen date and time window.';

  @override
  String get policyConfirmationDetailsTitle =>
      'Appointment Confirmation Details';

  @override
  String get policyConfirmationDetailsP1 =>
      'Once confirmed, your token display code (e.g. TAX-001), appointment date, fixed time slot, civic centre, and party size will be registered.';

  @override
  String get policyConfirmationDetailsP2 =>
      'Your appointment is visible on the Home screen and Live Token screen, showing live queue status and waiting count if scheduled for today.';

  @override
  String get policyConfirmationDetailsP3 =>
      'Remember to carry all original documents, copies, and your registered mobile phone when visiting the centre.';

  @override
  String get policySlotFeesTitle => 'Fixed Appointment Slots & Pricing';

  @override
  String get policySlotFeesP1 =>
      'QueueLess appointments are fixed slots. Your appointment time is never automatically shifted merely because another person is absent.';

  @override
  String get policySlotFeesP2 =>
      'Standard appointments within 2 days carry a standard fee of ₹20.';

  @override
  String get policySlotFeesP3 =>
      'Advance custom slots (3+ days ahead) display a ₹50 slot fee in the app. Currently, all fee displays are demo/system-simulated, and no real monetary deduction occurs.';

  @override
  String get policySlotFeesP4 =>
      'Statutory Disclosure: A booked slot does not protect against unexpected government emergency closures, gazetted holidays, or server interruptions.';

  @override
  String get policyArrivalAndCheckinTitle =>
      'Arrival & Physical Presence Check-In';

  @override
  String get policyArrivalAndCheckinP1 =>
      'Citizens must physically arrive at the civic centre at or slightly before their designated appointment slot.';

  @override
  String get policyArrivalAndCheckinP2 =>
      'To verify physical presence, scan the official QR code at the entrance using the app. Remote or fake check-in is strictly prevented.';

  @override
  String get policyArrivalAndCheckinP3 =>
      'Note the difference: Your appointment slot is your official scheduled time, while live queue position and estimated wait show real-time counter pace.';

  @override
  String get policyOnMyWayGraceTitle => '\"I\'m On My Way\" & Grace Period';

  @override
  String get policyOnMyWayGraceP1 =>
      'If you are briefly delayed in transit, you can tap the \"I\'m On My Way\" button while your token is in Waiting or Called state.';

  @override
  String get policyOnMyWayGraceP2 =>
      'This grants a configured one-time 5-minute extension to your arrival grace deadline.';

  @override
  String get policyOnMyWayGraceP3 =>
      'This extension can only be used once per appointment. A second attempt is rejected by the system.';

  @override
  String get policyOnMyWayGraceP4 =>
      'Using this extension provides extra arrival time but does not permanently change your booked appointment slot.';

  @override
  String get policyServiceCompletionTitle =>
      'Service Delivery & Double-Verification';

  @override
  String get policyServiceCompletionP1 =>
      'When called, proceed to the assigned counter. The officer will physically examine your documents and provide the requested civic service.';

  @override
  String get policyServiceCompletionP2 =>
      'Upon service conclusion, the counter officer records the outcome and the actual number of individuals served.';

  @override
  String get policyServiceCompletionP3 =>
      'For online appointments, a double-confirmation prompt appears in your app to confirm successful service completion.';

  @override
  String get policyServiceCompletionP4 =>
      'You can submit a 1 to 5 star rating and optional comments to help improve civic service standards.';

  @override
  String get policyCantAttendDelayClosureTitle =>
      'Cancellations, Office Delays & Closures';

  @override
  String get policyCantAttendDelayClosureP1 =>
      'If you cannot attend, you can cancel your appointment from the app while it is in Waiting or Called state. No cancellation penalties apply.';

  @override
  String get policyCantAttendDelayClosureP2 =>
      'Self-service rescheduling is not currently available. To choose a different time, cancel your active token and book a new available slot.';

  @override
  String get policyCantAttendDelayClosureP3 =>
      'Cancellation is not permitted once service delivery has begun (Serving state) or after the service is completed.';

  @override
  String get policyCantAttendDelayClosureP4 =>
      'Official delays: Government counter delays are not the citizen\'s fault. The app displays real-time delay notices. Appointments are not falsely moved.';

  @override
  String get policyCantAttendDelayClosureP5 =>
      'Centre closures: If an office or service is temporarily closed for emergencies or holidays, new bookings are blocked. Affected citizens should re-book when reopened or visit the Help Desk.';

  @override
  String get policyNoShowDispatchTitle => 'Late Arrival & No-Show Policy';

  @override
  String get policyNoShowDispatchP1 =>
      'If an appointment holder fails to arrive or check in before the grace deadline expires, the token may be passed over or marked No-Show.';

  @override
  String get policyNoShowDispatchP2 =>
      'Counters do not sit idle waiting for absent citizens. When an online appointment holder is absent, waiting physical walk-in citizens may be served according to fair dispatch rules.';

  @override
  String get policyTroubleshootingTitle =>
      'Troubleshooting (What Should I Do?)';

  @override
  String get policyTroubleshootingP1 =>
      'Forgot documents: Counter officers cannot process incomplete applications. You will need to cancel and book again once original documents are ready.';

  @override
  String get policyTroubleshootingP2 =>
      'Booked wrong service: Cancel the active appointment in the app and immediately select the correct service from the directory.';

  @override
  String get policyTroubleshootingP3 =>
      'System or network issue: Refresh your active token screen or seek immediate assistance at the Civic Centre Help Desk.';

  @override
  String get policyTroubleshootingP4 =>
      'Need help? Call the official toll-free citizen helpline: 1800-233-5500 (8:00 AM – 8:00 PM).';

  @override
  String get policyMultipleServicesDuplicatesTitle =>
      'Multiple Services & Duplicate Bookings';

  @override
  String get policyMultipleServicesDuplicatesP1 =>
      'Different services are handled by specialized counters. If you require multiple distinct civic services, each must be booked separately.';

  @override
  String get policyMultipleServicesDuplicatesP2 =>
      'Unified multi-service family bundles are not currently supported by the system.';

  @override
  String get policyMultipleServicesDuplicatesP3 =>
      'Duplicate booking prevention: QueueLess allows only one active token per phone number for the same service on the same date. Attempting a second active booking is blocked.';

  @override
  String get policyFamilyGroupTitle => 'Family & Group Booking Rules';

  @override
  String get policyFamilyGroupP1 =>
      'A citizen can book on behalf of family members by specifying the group size (1 to 5+ people) during booking.';

  @override
  String get policyFamilyGroupP2 =>
      'The selected party size must represent the people who will actually attend the civic centre together.';

  @override
  String get policyFamilyGroupP3 =>
      'When completing the service, the officer records the exact count of people who were actually served.';

  @override
  String get policyPhysicalWalkinsTitle =>
      'Physical Walk-In Citizens (No Smartphone)';

  @override
  String get policyPhysicalWalkinsP1 =>
      'Citizens who do not have a smartphone or internet access can visit the Civic Centre Help Desk in person.';

  @override
  String get policyPhysicalWalkinsP2 =>
      'Help desk staff will issue a physical paper token (e.g. P-001) printed with an estimated turn time.';

  @override
  String get policyPhysicalWalkinsP3 =>
      'Physical walk-in citizens join the same unified queue and are served fairly alongside online appointments.';

  @override
  String get policyPriorityAssistanceTitle => 'Priority Assistance Policy';

  @override
  String get policyPriorityAssistanceP1 =>
      'Online booking no longer allows self-selecting priority access, ensuring fair queue access for all citizens.';

  @override
  String get policyPriorityAssistanceP2 =>
      'Eligible citizens (seniors aged 60+, pregnant women, and persons with disabilities) receive priority verification in person at the Help Desk or counter upon showing valid proof.';

  @override
  String get helpAndRulesTitle => 'Help & Rules';

  @override
  String get helpAndRulesSubtitle =>
      'Important information about appointments, arrival, cancellation and service.';

  @override
  String get helpAndRulesAction => 'Help & Rules';

  @override
  String get helpAndPoliciesSection => 'Help & Policies';

  @override
  String get viewAppointmentRulesAction =>
      'View appointment & cancellation rules';

  @override
  String get importantCivicNoticeTitle => 'Important Notice';

  @override
  String get importantCivicNoticeBody =>
      'QueueLess helps manage appointments and queues. Final service decisions, document acceptance, eligibility, government deadlines, and official closures remain under the responsibility of the concerned civic authority.';

  @override
  String get categoryBookingRules => '1. Booking Rules';

  @override
  String get categoryArrivalService => '2. Arrival & Service Delivery';

  @override
  String get categoryChangesDelays => '3. Problems & What To Do';

  @override
  String get categorySpecialRules => '4. Special Categories & System Rules';

  @override
  String get secHowAppointmentsWorkTitle => 'How QueueLess Appointments Work';

  @override
  String get secHowAppointmentsWorkP1 =>
      'To schedule a civic service: Select your city, choose your nearest civic centre, and pick the required municipal service.';

  @override
  String get secHowAppointmentsWorkP2 =>
      'Review the required document checklist and confirm all originals are ready. Then pick an available working date and fixed time slot.';

  @override
  String get secHowAppointmentsWorkP3 =>
      'Select the number of people coming (1 to 5+), confirm your booking, and receive an instant token confirmation with your assigned date and time window.';

  @override
  String get secHowAppointmentsWorkP4 =>
      'QueueLess appointments use fixed time slots. You must arrive at the civic centre according to your booked slot.';

  @override
  String get secAppointmentConfirmationTitle =>
      'Appointment Confirmation Details';

  @override
  String get secAppointmentConfirmationP1 =>
      'Upon booking, your confirmation displays: Appointment date, fixed time slot, civic centre location, service type, party size, token code, and fee tier.';

  @override
  String get secAppointmentConfirmationP2 =>
      'Confirmation registers your appointment in the system. It does not guarantee that the government office will never experience operational delays or emergency closures.';

  @override
  String get secRequiredDocumentsTitle => 'Required Document Checklist';

  @override
  String get secRequiredDocumentsP1 =>
      'Every municipal service specifies mandatory required documents. Review this checklist carefully before scheduling.';

  @override
  String get secRequiredDocumentsP2 =>
      'The confirmation checkbox confirms you have all original documents and copies ready in hand. The app does not electronically verify documents.';

  @override
  String get secRequiredDocumentsP3 =>
      'Visiting with missing or invalid documents will result in the counter officer being unable to deliver the service.';

  @override
  String get secSlotFeesTitle => 'Custom & Future Appointment Fees';

  @override
  String get secSlotFeesP1 =>
      'Standard appointment slots within 2 days carry a standard fee of ₹20.';

  @override
  String get secSlotFeesP2 =>
      'Custom advance slots (3+ days ahead) display a ₹50 slot fee in the app. All fees are currently system-simulated for demonstration; no real money is deducted.';

  @override
  String get secSlotFeesP3 =>
      'A fee never buys priority over other citizens and never guarantees service. It does not protect against official closures or system downtime.';

  @override
  String get secAdvanceDeadlinesTitle =>
      'Advance Booking & Government Deadlines';

  @override
  String get secAdvanceDeadlinesP1 =>
      'The civic department or administrator may close online advance booking ahead of official government deadlines or holiday periods.';

  @override
  String get secAdvanceDeadlinesP2 =>
      'When online booking is closed for a service, citizens must visit the civic centre in person and follow the physical counter process.';

  @override
  String get secArrivalCheckinTitle => 'Arrival & Entrance QR Check-In';

  @override
  String get secArrivalCheckinP1 =>
      'Arrive at the civic centre on time for your scheduled appointment slot.';

  @override
  String get secArrivalCheckinP2 =>
      'Upon entering the building, scan the official entrance QR code with your app to confirm physical presence.';

  @override
  String get secArrivalCheckinP3 =>
      'Remote, premature, or invalid QR scans are rejected. Live queue position and waiting ahead count become active once you arrive.';

  @override
  String get secOnMyWayTitle => '\"I\'m On My Way\" (+5 Minutes Extension)';

  @override
  String get secOnMyWayP1 =>
      'If briefly delayed in transit, tap \"I\'m On My Way\" while your token is in Waiting or Called status.';

  @override
  String get secOnMyWayP2 =>
      'This feature provides a one-time 5-minute extension to your arrival grace buffer.';

  @override
  String get secOnMyWayP3 =>
      'It cannot be repeatedly claimed, does not change your original slot time, and does not guarantee immediate counter service upon arrival.';

  @override
  String get secIfLateTitle => 'If I Am Late';

  @override
  String get secIfLateP1 =>
      'If you are running late, still proceed to the civic centre as quickly as possible.';

  @override
  String get secIfLateP2 =>
      'If you fail to arrive within the grace window, the officer may call another waiting citizen to keep counters productive.';

  @override
  String get secIfLateP3 =>
      'Being late does not automatically push your appointment forward to a later time.';

  @override
  String get secNoShowTitle => 'No-Show & Fair Dispatch';

  @override
  String get secNoShowP1 =>
      'If an online appointment holder does not check in within the grace window, the counter officer manually calls the next eligible citizen.';

  @override
  String get secNoShowP2 =>
      'Waiting physical walk-in citizens may be served during unused capacity so government staff do not sit idle.';

  @override
  String get secServiceCompletionTitle =>
      'Service Completion & Double-Confirmation';

  @override
  String get secServiceCompletionP1 =>
      'At the counter, the officer examines physical documents and records the service outcome (Successful, Partial, or Missing Documents).';

  @override
  String get secServiceCompletionP2 =>
      'For online appointments, a double-confirmation prompt appears in your mobile app so you can verify that service delivery occurred.';

  @override
  String get secRatingFeedbackTitle => 'Rating & Citizen Feedback';

  @override
  String get secRatingFeedbackP1 =>
      'After confirming service completion, you can submit a 1 to 5 star rating and optional comments.';

  @override
  String get secRatingFeedbackP2 =>
      'Your feedback helps the department improve civic service quality. Feedback does not impact queue priority or future bookings.';

  @override
  String get secCancellationRulesTitle => 'Cancellation Rules';

  @override
  String get secCancellationRulesP1 =>
      'You may cancel your appointment from the app anytime while your token is in Waiting or Called status before service starts.';

  @override
  String get secCancellationRulesP2 =>
      'Once the counter officer begins serving you (Serving status) or after service completion, cancellation is no longer permitted.';

  @override
  String get secCancellationRulesP3 =>
      'QueueLess charges no cancellation fees or penalties for cancelling an active appointment.';

  @override
  String get secReschedulingPolicyTitle => 'Rescheduling Policy';

  @override
  String get secReschedulingPolicyP1 =>
      'Self-service automatic rescheduling is currently NOT available in the system.';

  @override
  String get secReschedulingPolicyP2 =>
      'If you cannot attend, cancel your active token in the app and book a fresh available slot for another day or time.';

  @override
  String get secOfficeDelaysTitle => 'Government & Office Delays';

  @override
  String get secOfficeDelaysP1 =>
      'If the government office, counter, department network, or biometric system causes a delay, the citizen is not held responsible.';

  @override
  String get secOfficeDelaysP2 =>
      'Your booked slot does not silently shift. The app displays real-time delay notices and queue status. Please follow in-office guidance.';

  @override
  String get secOfficeClosuresTitle => 'Civic Centre & Counter Closures';

  @override
  String get secOfficeClosuresP1 =>
      'A civic centre, service, or counter may close temporarily due to an emergency, administrative order, or gazetted holiday.';

  @override
  String get secOfficeClosuresP2 =>
      'When closed, new bookings are blocked. Premium or custom appointment fees do not guarantee service during official closures.';

  @override
  String get secServerFailuresTitle => 'Server & Technical Outages';

  @override
  String get secServerFailuresP1 =>
      'If a service or counter encounters technical issues, the office administrator may pause the affected queue while others continue.';

  @override
  String get secServerFailuresP2 =>
      'Automatic rescheduling for prolonged outages is not currently available. Please follow the instructions provided by the civic centre.';

  @override
  String get secTroubleshootingTitle =>
      'Troubleshooting (What To Do If Something Goes Wrong)';

  @override
  String get secTroubleshootingP1 =>
      'Appointment not showing: Ensure you are logged in with the mobile number used during booking and pull down to refresh.';

  @override
  String get secTroubleshootingP2 =>
      'Cannot check in or QR failing: Verify camera permissions and ensure you are scanning the official QR displayed at the entrance.';

  @override
  String get secTroubleshootingP3 =>
      'Required document missing: Cancel your active token and re-book after obtaining all required original documents.';

  @override
  String get secTroubleshootingP4 =>
      'Office delayed or counter closed: Check the live app queue status and consult the civic centre Help Desk.';

  @override
  String get secTroubleshootingP5 =>
      'Duplicate booking message: You already hold an active token for this service today; complete or cancel it before booking again.';

  @override
  String get secTroubleshootingP6 =>
      'Citizen Helpline: For urgent questions, call the official toll-free helpline: 1800-233-5500 (8:00 AM – 8:00 PM).';

  @override
  String get secFamilyGroupTitle => 'Family & Group Bookings';

  @override
  String get secFamilyGroupP1 =>
      'One citizen can book on behalf of family members by selecting group size (1 to 4 people).';

  @override
  String get secFamilyGroupP2 =>
      'All group members must attend together with their respective required documents. The officer records the count of persons actually served.';

  @override
  String get secFamilyGroupP3 =>
      'One booking does not create a multi-service bundle; it covers the selected service only.';

  @override
  String get secMultipleServicesTitle => 'Multiple Services Booking';

  @override
  String get secMultipleServicesP1 =>
      'Different municipal services are handled by distinct specialized counters.';

  @override
  String get secMultipleServicesP2 =>
      'If you require multiple separate services, you must make a separate booking for each service.';

  @override
  String get secDuplicateBookingTitle => 'Duplicate Booking Prevention';

  @override
  String get secDuplicateBookingP1 =>
      'QueueLess strictly prevents duplicate active bookings for the same citizen/phone for the same service on the same date.';

  @override
  String get secDuplicateBookingP2 =>
      'You cannot hold two concurrent active tokens for the same service. Cancel your existing booking first if you need to change times.';

  @override
  String get secPhysicalWalkinsTitle => 'Physical Walk-In Citizens (Help Desk)';

  @override
  String get secPhysicalWalkinsP1 =>
      'Citizens without a smartphone or internet access can visit the civic centre Help Desk in person.';

  @override
  String get secPhysicalWalkinsP2 =>
      'Help desk staff generate a physical paper token (e.g. P-001) printed with an estimated turn time.';

  @override
  String get secPhysicalWalkinsP3 =>
      'Physical and online citizens share the same operational queue and are dispatched fairly by counter officers.';

  @override
  String get secPriorityCitizensTitle => 'Priority Assistance Eligibility';

  @override
  String get secPriorityCitizensP1 =>
      'Priority access is reserved for senior citizens (60+), pregnant women, and persons with disabilities (PwD).';

  @override
  String get secPriorityCitizensP2 =>
      'Online booking does not allow self-selecting priority access. Eligibility is verified in-person at the Help Desk or counter upon showing valid proof.';

  @override
  String get secPrivacyDisplayTitle => 'Privacy & Lobby Display Policy';

  @override
  String get secPrivacyDisplayP1 =>
      'Public TV and counter displays show token display codes only (e.g. TAX-001 at Counter 2).';

  @override
  String get secPrivacyDisplayP2 =>
      'Citizen names, phone numbers, and identity documents are never displayed publicly. Keep your registered phone secure.';

  @override
  String get showVerificationCodeToOfficer =>
      'Show this QR code to the counter officer or provide your 6-digit verification code before service starts.';

  @override
  String get counterVerificationSecretLabel => 'Verification Code';

  @override
  String get secCounterVerificationTitle =>
      'Mandatory Counter Token Verification';

  @override
  String get secCounterVerificationP1 =>
      'Before beginning service, the counter officer must verify your token. Service cannot begin simply because your token was called.';

  @override
  String get secCounterVerificationP2 =>
      'Provide the 6-digit verification code or show the QR code displayed on your app screen (or on your printed Turn Slip). The public token code shown on lobby screens cannot be used for verification.';

  @override
  String get secCounterVerificationP3 =>
      'Verification secrets are single-use and bound to your assigned counter. If you lose your slip or phone, an authorized officer can apply a logged administrative override with an official reason.';

  @override
  String get accompanyingPersonsSectionTitle =>
      'Accompanying Persons Details (Max 4 Total)';

  @override
  String get sameCounterOnlyNotice =>
      'Single Counter Policy: All accompanying members must attend for this same counter service. Any person needing work at another counter or department must book a separate appointment.';

  @override
  String personIndexLabel(int number) {
    return 'Accompanying Person #$number';
  }

  @override
  String get accompanyingPersonNameHint => 'Full Name (as per identity proof)';

  @override
  String get coAttendanceReasonLabel =>
      'Reason for Co-Attendance at this Counter';

  @override
  String get selectCoAttendanceReasonPrompt =>
      'Select valid reason for this counter';

  @override
  String get reasonJointApplicant =>
      'Joint Property Owner / Co-applicant for this service';

  @override
  String get reasonAssistance =>
      'Assistance for Senior Citizen / Differently-Abled applicant';

  @override
  String get reasonGuardian => 'Legal Guardian / Authorized Representative';

  @override
  String get reasonWitnessSignatory =>
      'Witness / Deponent / Signatory for document verification';

  @override
  String get reasonFamilyVerification =>
      'Family member required for joint identity verification';

  @override
  String get reasonOtherCounterWork =>
      'Work at a different counter/department (Separate booking required)';

  @override
  String get invalidCounterReasonError =>
      'Not allowed: Accompanying person has work at another counter. Please book a separate appointment for that counter.';

  @override
  String get missingAccompanyingDetailsPrompt =>
      'Please provide full name and select a valid counter reason for all accompanying persons.';

  @override
  String get accompanyingPersonsSummary => 'Accompanying Persons:';
}
