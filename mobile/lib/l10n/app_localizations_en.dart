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
}
