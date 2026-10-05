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
}
