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
  String get nowServingAt => 'Currently Serving:';

  @override
  String get chooseDateTimeSlot => 'Choose Date & Time Slot';

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
  String get within2DaysFeeFree => 'Within 2 Days • ₹0 Fee';

  @override
  String get customDateFee50 => 'Custom Date • ₹50 Fee';

  @override
  String get normalSlotTitle =>
      'Normal Slot (Within 2 Days) • Free / ₹0 Standard Fee';

  @override
  String get customSlotTitle => 'Custom Future Slot • Higher Fee (₹50)';

  @override
  String get statutoryDisclosure =>
      'Statutory Disclosure (Spec Section 6.3): A custom slot fee does not protect against official department emergency closures, gazetted holidays, or government server delay.';

  @override
  String get standardNearTermNotice =>
      'Standard near-term booking within 2 days carries no additional fee.';

  @override
  String get availableTimeSlotsTitle => 'Available Time Slots';

  @override
  String get slotsFullWarning =>
      'Slots are full for this time! Please select another available slot or another day. Booking any available normal slot within 2 days carries zero extra fees.';

  @override
  String get slotsFullBadge => 'Slots Full';

  @override
  String get availableBadge => 'Available';

  @override
  String get peopleCountPrompt =>
      'How many people are coming with you? (Spec Section 7.2)';

  @override
  String get confirmAppointmentStandard =>
      'Confirm Appointment • Standard Fee: ₹0';

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
  String get standardFreeTier => 'Standard / Free (₹0)';

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
}
