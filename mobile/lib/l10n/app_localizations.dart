import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'QueueLess'**
  String get appName;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Service Appointments'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book fixed appointments, track your turn live, and avoid waiting in lines.'**
  String get welcomeSubtitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Your Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી (Gujarati)'**
  String get gujarati;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get hindi;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Phone'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to receive a verification OTP.'**
  String get loginSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get phoneNumber;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-Digit OTP'**
  String get enterOtp;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify & Enter'**
  String get verifyOtp;

  /// No description provided for @browseOffices.
  ///
  /// In en, this message translates to:
  /// **'Select Civic Centre'**
  String get browseOffices;

  /// No description provided for @browseServices.
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get browseServices;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get requiredDocuments;

  /// No description provided for @confirmDocumentsPrompt.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I have all required original documents ready for this visit.'**
  String get confirmDocumentsPrompt;

  /// No description provided for @checkAllDocsFirstNotice.
  ///
  /// In en, this message translates to:
  /// **'Please tick every required document above first.'**
  String get checkAllDocsFirstNotice;

  /// No description provided for @docsVerifiedProgress.
  ///
  /// In en, this message translates to:
  /// **'{checked} of {total} checked'**
  String docsVerifiedProgress(int checked, int total);

  /// No description provided for @bookSlot.
  ///
  /// In en, this message translates to:
  /// **'Book Fixed Appointment'**
  String get bookSlot;

  /// No description provided for @familyCount.
  ///
  /// In en, this message translates to:
  /// **'Number of People Coming'**
  String get familyCount;

  /// No description provided for @myToken.
  ///
  /// In en, this message translates to:
  /// **'My Active Token'**
  String get myToken;

  /// No description provided for @appointmentTime.
  ///
  /// In en, this message translates to:
  /// **'Appointment Time'**
  String get appointmentTime;

  /// No description provided for @estimatedTurn.
  ///
  /// In en, this message translates to:
  /// **'Estimated Turn'**
  String get estimatedTurn;

  /// No description provided for @nowServing.
  ///
  /// In en, this message translates to:
  /// **'Now Serving'**
  String get nowServing;

  /// No description provided for @waitingAhead.
  ///
  /// In en, this message translates to:
  /// **'Waiting Ahead'**
  String get waitingAhead;

  /// No description provided for @checkInQr.
  ///
  /// In en, this message translates to:
  /// **'Presence Check-In'**
  String get checkInQr;

  /// No description provided for @scanEntranceQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Entrance QR to Confirm Arrival'**
  String get scanEntranceQr;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @confirmCompletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Service Completion'**
  String get confirmCompletion;

  /// No description provided for @leaveNowAlert.
  ///
  /// In en, this message translates to:
  /// **'Leave Now: Your turn is approaching!'**
  String get leaveNowAlert;

  /// No description provided for @doubleConfirmationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Officer has marked service completed. Please confirm below:'**
  String get doubleConfirmationPrompt;

  /// No description provided for @serviceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Service Successfully Completed'**
  String get serviceCompleted;

  /// No description provided for @officesTitle.
  ///
  /// In en, this message translates to:
  /// **'Civic Centres'**
  String get officesTitle;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Services'**
  String get servicesTitle;

  /// No description provided for @selectOfficePrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose your nearest municipal or ward office.'**
  String get selectOfficePrompt;

  /// No description provided for @selectServicePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select the civic service you need assistance with.'**
  String get selectServicePrompt;

  /// No description provided for @noOfficesFound.
  ///
  /// In en, this message translates to:
  /// **'No civic centres currently available.'**
  String get noOfficesFound;

  /// No description provided for @noServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services available at this centre.'**
  String get noServicesFound;

  /// No description provided for @documentChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Required Document Checklist'**
  String get documentChecklistTitle;

  /// No description provided for @documentChecklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please ensure you have originals and copies of the following documents before visiting the office:'**
  String get documentChecklistSubtitle;

  /// No description provided for @categorySelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Category'**
  String get categorySelectionTitle;

  /// No description provided for @categoryNormalLabel.
  ///
  /// In en, this message translates to:
  /// **'General / Normal'**
  String get categoryNormalLabel;

  /// No description provided for @categoryPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority Access'**
  String get categoryPriorityLabel;

  /// No description provided for @categoryPriorityNotice.
  ///
  /// In en, this message translates to:
  /// **'Reserved for senior citizens (60+), pregnant women, and persons with disabilities. Valid ID/proof required upon arrival.'**
  String get categoryPriorityNotice;

  /// No description provided for @beneficiaryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary Name (Optional)'**
  String get beneficiaryNameLabel;

  /// No description provided for @beneficiaryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of the person being served'**
  String get beneficiaryNameHint;

  /// No description provided for @bookAppointmentAction.
  ///
  /// In en, this message translates to:
  /// **'Book Fixed Appointment'**
  String get bookAppointmentAction;

  /// No description provided for @bookingConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmed!'**
  String get bookingConfirmationTitle;

  /// No description provided for @bookingSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your appointment has been registered. Arrive on time to ensure prompt service.'**
  String get bookingSuccessMessage;

  /// No description provided for @viewTokenAction.
  ///
  /// In en, this message translates to:
  /// **'View My Token'**
  String get viewTokenAction;

  /// No description provided for @onlineAlternativeNotice.
  ///
  /// In en, this message translates to:
  /// **'This service is also available online! You can save a visit by using the official online portal.'**
  String get onlineAlternativeNotice;

  /// No description provided for @openOnlineLink.
  ///
  /// In en, this message translates to:
  /// **'Open Online Portal'**
  String get openOnlineLink;

  /// No description provided for @avgServiceDuration.
  ///
  /// In en, this message translates to:
  /// **'Average Service Duration'**
  String get avgServiceDuration;

  /// No description provided for @currentQueueWait.
  ///
  /// In en, this message translates to:
  /// **'Current Queue Wait'**
  String get currentQueueWait;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @officeHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get officeHoursLabel;

  /// No description provided for @onMyWayAction.
  ///
  /// In en, this message translates to:
  /// **'I\'m on My Way (+5 min)'**
  String get onMyWayAction;

  /// No description provided for @onMyWaySuccess.
  ///
  /// In en, this message translates to:
  /// **'Extra 5 minutes grace period granted!'**
  String get onMyWaySuccess;

  /// No description provided for @onMyWayClaimed.
  ///
  /// In en, this message translates to:
  /// **'Extension Claimed'**
  String get onMyWayClaimed;

  /// No description provided for @presenceVerified.
  ///
  /// In en, this message translates to:
  /// **'Arrival Verified at Centre'**
  String get presenceVerified;

  /// No description provided for @enterQrCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter or Scan Entrance QR Code'**
  String get enterQrCodePrompt;

  /// No description provided for @confirmCancelPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this appointment?'**
  String get confirmCancelPrompt;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation (optional)'**
  String get cancelReasonLabel;

  /// No description provided for @etaRangePrefix.
  ///
  /// In en, this message translates to:
  /// **'Estimated Turn Window:'**
  String get etaRangePrefix;

  /// No description provided for @nowServingAt.
  ///
  /// In en, this message translates to:
  /// **'Now Serving At:'**
  String get nowServingAt;

  /// No description provided for @chooseDateTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Choose an Available Appointment Slot'**
  String get chooseDateTimeSlot;

  /// No description provided for @chooseAvailableSlotInstruction.
  ///
  /// In en, this message translates to:
  /// **'Select an available fixed appointment slot from the schedule below.'**
  String get chooseAvailableSlotInstruction;

  /// No description provided for @selectedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected Date'**
  String get selectedDateLabel;

  /// No description provided for @openCalendarAction.
  ///
  /// In en, this message translates to:
  /// **'Open Calendar'**
  String get openCalendarAction;

  /// No description provided for @quickSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Selection'**
  String get quickSelectionTitle;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @tomorrowLabel.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrowLabel;

  /// No description provided for @in2DaysLabel.
  ///
  /// In en, this message translates to:
  /// **'In 2 Days'**
  String get in2DaysLabel;

  /// No description provided for @in3DaysLabel.
  ///
  /// In en, this message translates to:
  /// **'In 3 Days'**
  String get in3DaysLabel;

  /// No description provided for @within2DaysFeeFree.
  ///
  /// In en, this message translates to:
  /// **'Within 2 Days • ₹20 Fee'**
  String get within2DaysFeeFree;

  /// No description provided for @customDateFee50.
  ///
  /// In en, this message translates to:
  /// **'Custom Date • ₹50 Fee'**
  String get customDateFee50;

  /// No description provided for @normalSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal Slot (Within 2 Days) • ₹20 Standard Fee'**
  String get normalSlotTitle;

  /// No description provided for @customSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Future Slot • Higher Fee (₹50)'**
  String get customSlotTitle;

  /// No description provided for @statutoryDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Statutory Disclosure (Spec Section 6.3): A custom slot fee does not protect against official department emergency closures, gazetted holidays, or government server delay.'**
  String get statutoryDisclosure;

  /// No description provided for @standardNearTermNotice.
  ///
  /// In en, this message translates to:
  /// **'Standard near-term booking within 2 days carries a ₹20 booking fee.'**
  String get standardNearTermNotice;

  /// No description provided for @availableTimeSlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Time Slots'**
  String get availableTimeSlotsTitle;

  /// No description provided for @slotsFullWarning.
  ///
  /// In en, this message translates to:
  /// **'Slots are full for this time! Please select another available slot or another day. Booking any available normal slot within 2 days carries a ₹20 standard fee.'**
  String get slotsFullWarning;

  /// No description provided for @slotsFullBadge.
  ///
  /// In en, this message translates to:
  /// **'Slots Full'**
  String get slotsFullBadge;

  /// No description provided for @availableBadge.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableBadge;

  /// No description provided for @peopleCountPrompt.
  ///
  /// In en, this message translates to:
  /// **'How many people are coming with you? (Spec Section 7.2)'**
  String get peopleCountPrompt;

  /// No description provided for @confirmAppointmentStandard.
  ///
  /// In en, this message translates to:
  /// **'Confirm Appointment • Standard Fee: ₹20'**
  String get confirmAppointmentStandard;

  /// No description provided for @confirmAppointmentHigher.
  ///
  /// In en, this message translates to:
  /// **'Confirm Appointment • Higher Fee: ₹50'**
  String get confirmAppointmentHigher;

  /// No description provided for @applicantDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Applicant Details'**
  String get applicantDetailsTitle;

  /// No description provided for @dateSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get dateSummaryLabel;

  /// No description provided for @slotTimeSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Slot Time:'**
  String get slotTimeSummaryLabel;

  /// No description provided for @partySizeSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Party Size:'**
  String get partySizeSummaryLabel;

  /// No description provided for @feeTierSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee Tier:'**
  String get feeTierSummaryLabel;

  /// No description provided for @standardFreeTier.
  ///
  /// In en, this message translates to:
  /// **'Standard Slot (₹20)'**
  String get standardFreeTier;

  /// No description provided for @customPaidTier.
  ///
  /// In en, this message translates to:
  /// **'Custom Advance Slot (₹50)'**
  String get customPaidTier;

  /// No description provided for @onePerson.
  ///
  /// In en, this message translates to:
  /// **'1 Person'**
  String get onePerson;

  /// No description provided for @multiplePeople.
  ///
  /// In en, this message translates to:
  /// **'{count} People'**
  String multiplePeople(Object count);

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'QueueLess Sign In'**
  String get signInTitle;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile Number'**
  String get enterMobileNumber;

  /// No description provided for @invalidPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get invalidPhoneError;

  /// No description provided for @invalidOtpError.
  ///
  /// In en, this message translates to:
  /// **'Please enter 6-digit OTP'**
  String get invalidOtpError;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// No description provided for @sendOtpAction.
  ///
  /// In en, this message translates to:
  /// **'Get Verification Code'**
  String get sendOtpAction;

  /// No description provided for @verifyOtpAction.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP & Enter'**
  String get verifyOtpAction;

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-Digit OTP'**
  String get otpLabel;

  /// No description provided for @activeAppointmentBanner.
  ///
  /// In en, this message translates to:
  /// **'Active Appointment in Progress'**
  String get activeAppointmentBanner;

  /// No description provided for @tapToViewEta.
  ///
  /// In en, this message translates to:
  /// **'Token: {code} • Tap to view live ETA'**
  String tapToViewEta(String code);

  /// No description provided for @priorityAllowedBadge.
  ///
  /// In en, this message translates to:
  /// **'⭐ Priority Allowed'**
  String get priorityAllowedBadge;

  /// No description provided for @seniorCitizenCategory.
  ///
  /// In en, this message translates to:
  /// **'Senior Citizen (60+ years)'**
  String get seniorCitizenCategory;

  /// No description provided for @pregnantCategory.
  ///
  /// In en, this message translates to:
  /// **'Pregnant / Nursing Mother'**
  String get pregnantCategory;

  /// No description provided for @disabilityCategory.
  ///
  /// In en, this message translates to:
  /// **'Person with Disability (PwD)'**
  String get disabilityCategory;

  /// No description provided for @medicalCategory.
  ///
  /// In en, this message translates to:
  /// **'Medical Urgency / Health'**
  String get medicalCategory;

  /// No description provided for @eligibilityCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Category'**
  String get eligibilityCategoryLabel;

  /// No description provided for @signOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutTooltip;

  /// No description provided for @keepAppointmentAction.
  ///
  /// In en, this message translates to:
  /// **'Keep Appointment'**
  String get keepAppointmentAction;

  /// No description provided for @yesCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancelAction;

  /// No description provided for @cancelSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Appointment successfully cancelled'**
  String get cancelSuccessMessage;

  /// No description provided for @priorityBadge.
  ///
  /// In en, this message translates to:
  /// **'⭐ Priority'**
  String get priorityBadge;

  /// No description provided for @notCheckedInStatus.
  ///
  /// In en, this message translates to:
  /// **'Not Yet Checked In'**
  String get notCheckedInStatus;

  /// No description provided for @calculatingEta.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get calculatingEta;

  /// No description provided for @noActiveAppointment.
  ///
  /// In en, this message translates to:
  /// **'No Active Appointment'**
  String get noActiveAppointment;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @verifyArrivalAction.
  ///
  /// In en, this message translates to:
  /// **'Verify Arrival'**
  String get verifyArrivalAction;

  /// No description provided for @qrCodeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to the entrance officer or counter scanner to verify your arrival.'**
  String get qrCodeInstruction;

  /// No description provided for @manualVerificationCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Token Verification Code'**
  String get manualVerificationCodePrompt;

  /// No description provided for @qrFallbackOfficerNotice.
  ///
  /// In en, this message translates to:
  /// **'Share this code with the officer if the QR scanner faces any issue.'**
  String get qrFallbackOfficerNotice;

  /// No description provided for @appointmentConfirmedCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmed'**
  String get appointmentConfirmedCardTitle;

  /// No description provided for @appointmentFutureNotice.
  ///
  /// In en, this message translates to:
  /// **'Your appointment is confirmed for an upcoming date. Live queue status will activate on the day of your appointment when the office opens.'**
  String get appointmentFutureNotice;

  /// No description provided for @appointmentScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Date & Time'**
  String get appointmentScheduledFor;

  /// No description provided for @serviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get serviceLabel;

  /// No description provided for @civicCentreLabel.
  ///
  /// In en, this message translates to:
  /// **'Civic Centre'**
  String get civicCentreLabel;

  /// No description provided for @tokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Token Code'**
  String get tokenLabel;

  /// No description provided for @partySizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Party / Group Size'**
  String get partySizeLabel;

  /// No description provided for @feeLabel.
  ///
  /// In en, this message translates to:
  /// **'Applicable Fee'**
  String get feeLabel;

  /// No description provided for @feeDemoNotice.
  ///
  /// In en, this message translates to:
  /// **'Demo fee only • No payment gateway connected'**
  String get feeDemoNotice;

  /// No description provided for @feeFreeNotice.
  ///
  /// In en, this message translates to:
  /// **'Standard civic appointment • ₹20 Fee'**
  String get feeFreeNotice;

  /// No description provided for @liveQueueActiveNotice.
  ///
  /// In en, this message translates to:
  /// **'Active Office Queue Tracking'**
  String get liveQueueActiveNotice;

  /// No description provided for @officeDelayAlert.
  ///
  /// In en, this message translates to:
  /// **'Office is currently experiencing a service delay. Your appointment time remains unchanged, but service may take longer than expected.'**
  String get officeDelayAlert;

  /// No description provided for @cancelNotAllowedNotice.
  ///
  /// In en, this message translates to:
  /// **'Cancellation cutoff has passed. This appointment cannot be cancelled online.'**
  String get cancelNotAllowedNotice;

  /// No description provided for @searchServicesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search services'**
  String get searchServicesPlaceholder;

  /// No description provided for @searchServicesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search services'**
  String get searchServicesTooltip;

  /// No description provided for @clearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchTooltip;

  /// No description provided for @centresOfferService.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 centre offers this service} other{{count} centres offer this service}}'**
  String centresOfferService(int count);

  /// No description provided for @serviceAvailableNotice.
  ///
  /// In en, this message translates to:
  /// **'→ {serviceName} available'**
  String serviceAvailableNotice(String serviceName);

  /// No description provided for @noCentresOfferService.
  ///
  /// In en, this message translates to:
  /// **'No civic centre in this city offers this service.'**
  String get noCentresOfferService;

  /// No description provided for @clearSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearchAction;

  /// No description provided for @rulesAndPoliciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules & Policies'**
  String get rulesAndPoliciesTitle;

  /// No description provided for @rulesAndPoliciesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What to do in different situations while using QueueLess'**
  String get rulesAndPoliciesSubtitle;

  /// No description provided for @rulesAndPoliciesAction.
  ///
  /// In en, this message translates to:
  /// **'Rules & Policies'**
  String get rulesAndPoliciesAction;

  /// No description provided for @viewAppointmentPoliciesAction.
  ///
  /// In en, this message translates to:
  /// **'View Appointment Policies'**
  String get viewAppointmentPoliciesAction;

  /// No description provided for @policyFooterHeading.
  ///
  /// In en, this message translates to:
  /// **'QueueLess Appointment & Service Policies'**
  String get policyFooterHeading;

  /// No description provided for @policyFooterVersion.
  ///
  /// In en, this message translates to:
  /// **'Official Civic System v1.1.0 • Gujarat e-Gov'**
  String get policyFooterVersion;

  /// No description provided for @policyTapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to view rules'**
  String get policyTapToExpand;

  /// No description provided for @policyTapToCollapse.
  ///
  /// In en, this message translates to:
  /// **'Tap to collapse'**
  String get policyTapToCollapse;

  /// No description provided for @categoryBooking.
  ///
  /// In en, this message translates to:
  /// **'1. Booking an Appointment'**
  String get categoryBooking;

  /// No description provided for @categoryOnTheDay.
  ///
  /// In en, this message translates to:
  /// **'2. On the Day of Visit'**
  String get categoryOnTheDay;

  /// No description provided for @categoryChangesProblems.
  ///
  /// In en, this message translates to:
  /// **'3. Changes & Problem Handling'**
  String get categoryChangesProblems;

  /// No description provided for @categorySpecialCases.
  ///
  /// In en, this message translates to:
  /// **'4. Special Categories & Walk-ins'**
  String get categorySpecialCases;

  /// No description provided for @policyBookingFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking an Appointment & Document Checklist'**
  String get policyBookingFlowTitle;

  /// No description provided for @policyBookingFlowP1.
  ///
  /// In en, this message translates to:
  /// **'To schedule an appointment, first select your city, your nearest civic centre, and the required municipal service.'**
  String get policyBookingFlowP1;

  /// No description provided for @policyBookingFlowP2.
  ///
  /// In en, this message translates to:
  /// **'Review the mandatory document checklist before booking. You must confirm that all required original documents are ready before the booking button is enabled.'**
  String get policyBookingFlowP2;

  /// No description provided for @policyBookingFlowP3.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred available date (Today, Tomorrow, or an upcoming working day) and a fixed time slot.'**
  String get policyBookingFlowP3;

  /// No description provided for @policyBookingFlowP4.
  ///
  /// In en, this message translates to:
  /// **'Select the number of people coming with the booking (1 to 5+). Your appointment is strictly locked to the chosen date and time window.'**
  String get policyBookingFlowP4;

  /// No description provided for @policyConfirmationDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmation Details'**
  String get policyConfirmationDetailsTitle;

  /// No description provided for @policyConfirmationDetailsP1.
  ///
  /// In en, this message translates to:
  /// **'Once confirmed, your token display code (e.g. TAX-001), appointment date, fixed time slot, civic centre, and party size will be registered.'**
  String get policyConfirmationDetailsP1;

  /// No description provided for @policyConfirmationDetailsP2.
  ///
  /// In en, this message translates to:
  /// **'Your appointment is visible on the Home screen and Live Token screen, showing live queue status and waiting count if scheduled for today.'**
  String get policyConfirmationDetailsP2;

  /// No description provided for @policyConfirmationDetailsP3.
  ///
  /// In en, this message translates to:
  /// **'Remember to carry all original documents, copies, and your registered mobile phone when visiting the centre.'**
  String get policyConfirmationDetailsP3;

  /// No description provided for @policySlotFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed Appointment Slots & Pricing'**
  String get policySlotFeesTitle;

  /// No description provided for @policySlotFeesP1.
  ///
  /// In en, this message translates to:
  /// **'QueueLess appointments are fixed slots. Your appointment time is never automatically shifted merely because another person is absent.'**
  String get policySlotFeesP1;

  /// No description provided for @policySlotFeesP2.
  ///
  /// In en, this message translates to:
  /// **'Standard appointments within 2 days carry a standard fee of ₹20.'**
  String get policySlotFeesP2;

  /// No description provided for @policySlotFeesP3.
  ///
  /// In en, this message translates to:
  /// **'Advance custom slots (3+ days ahead) display a ₹50 slot fee in the app. Currently, all fee displays are demo/system-simulated, and no real monetary deduction occurs.'**
  String get policySlotFeesP3;

  /// No description provided for @policySlotFeesP4.
  ///
  /// In en, this message translates to:
  /// **'Statutory Disclosure: A booked slot does not protect against unexpected government emergency closures, gazetted holidays, or server interruptions.'**
  String get policySlotFeesP4;

  /// No description provided for @policyArrivalAndCheckinTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrival & Physical Presence Check-In'**
  String get policyArrivalAndCheckinTitle;

  /// No description provided for @policyArrivalAndCheckinP1.
  ///
  /// In en, this message translates to:
  /// **'Citizens must physically arrive at the civic centre at or slightly before their designated appointment slot.'**
  String get policyArrivalAndCheckinP1;

  /// No description provided for @policyArrivalAndCheckinP2.
  ///
  /// In en, this message translates to:
  /// **'To verify physical presence, scan the official QR code at the entrance using the app. Remote or fake check-in is strictly prevented.'**
  String get policyArrivalAndCheckinP2;

  /// No description provided for @policyArrivalAndCheckinP3.
  ///
  /// In en, this message translates to:
  /// **'Note the difference: Your appointment slot is your official scheduled time, while live queue position and estimated wait show real-time counter pace.'**
  String get policyArrivalAndCheckinP3;

  /// No description provided for @policyOnMyWayGraceTitle.
  ///
  /// In en, this message translates to:
  /// **'\"I\'m On My Way\" & Grace Period'**
  String get policyOnMyWayGraceTitle;

  /// No description provided for @policyOnMyWayGraceP1.
  ///
  /// In en, this message translates to:
  /// **'If you are briefly delayed in transit, you can tap the \"I\'m On My Way\" button while your token is in Waiting or Called state.'**
  String get policyOnMyWayGraceP1;

  /// No description provided for @policyOnMyWayGraceP2.
  ///
  /// In en, this message translates to:
  /// **'This grants a configured one-time 5-minute extension to your arrival grace deadline.'**
  String get policyOnMyWayGraceP2;

  /// No description provided for @policyOnMyWayGraceP3.
  ///
  /// In en, this message translates to:
  /// **'This extension can only be used once per appointment. A second attempt is rejected by the system.'**
  String get policyOnMyWayGraceP3;

  /// No description provided for @policyOnMyWayGraceP4.
  ///
  /// In en, this message translates to:
  /// **'Using this extension provides extra arrival time but does not permanently change your booked appointment slot.'**
  String get policyOnMyWayGraceP4;

  /// No description provided for @policyServiceCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Delivery & Double-Verification'**
  String get policyServiceCompletionTitle;

  /// No description provided for @policyServiceCompletionP1.
  ///
  /// In en, this message translates to:
  /// **'When called, proceed to the assigned counter. The officer will physically examine your documents and provide the requested civic service.'**
  String get policyServiceCompletionP1;

  /// No description provided for @policyServiceCompletionP2.
  ///
  /// In en, this message translates to:
  /// **'Upon service conclusion, the counter officer records the outcome and the actual number of individuals served.'**
  String get policyServiceCompletionP2;

  /// No description provided for @policyServiceCompletionP3.
  ///
  /// In en, this message translates to:
  /// **'For online appointments, a double-confirmation prompt appears in your app to confirm successful service completion.'**
  String get policyServiceCompletionP3;

  /// No description provided for @policyServiceCompletionP4.
  ///
  /// In en, this message translates to:
  /// **'You can submit a 1 to 5 star rating and optional comments to help improve civic service standards.'**
  String get policyServiceCompletionP4;

  /// No description provided for @policyCantAttendDelayClosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellations, Office Delays & Closures'**
  String get policyCantAttendDelayClosureTitle;

  /// No description provided for @policyCantAttendDelayClosureP1.
  ///
  /// In en, this message translates to:
  /// **'If you cannot attend, you can cancel your appointment from the app while it is in Waiting or Called state. No cancellation penalties apply.'**
  String get policyCantAttendDelayClosureP1;

  /// No description provided for @policyCantAttendDelayClosureP2.
  ///
  /// In en, this message translates to:
  /// **'Self-service rescheduling is not currently available. To choose a different time, cancel your active token and book a new available slot.'**
  String get policyCantAttendDelayClosureP2;

  /// No description provided for @policyCantAttendDelayClosureP3.
  ///
  /// In en, this message translates to:
  /// **'Cancellation is not permitted once service delivery has begun (Serving state) or after the service is completed.'**
  String get policyCantAttendDelayClosureP3;

  /// No description provided for @policyCantAttendDelayClosureP4.
  ///
  /// In en, this message translates to:
  /// **'Official delays: Government counter delays are not the citizen\'s fault. The app displays real-time delay notices. Appointments are not falsely moved.'**
  String get policyCantAttendDelayClosureP4;

  /// No description provided for @policyCantAttendDelayClosureP5.
  ///
  /// In en, this message translates to:
  /// **'Centre closures: If an office or service is temporarily closed for emergencies or holidays, new bookings are blocked. Affected citizens should re-book when reopened or visit the Help Desk.'**
  String get policyCantAttendDelayClosureP5;

  /// No description provided for @policyNoShowDispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Late Arrival & No-Show Policy'**
  String get policyNoShowDispatchTitle;

  /// No description provided for @policyNoShowDispatchP1.
  ///
  /// In en, this message translates to:
  /// **'If an appointment holder fails to arrive or check in before the grace deadline expires, the token may be passed over or marked No-Show.'**
  String get policyNoShowDispatchP1;

  /// No description provided for @policyNoShowDispatchP2.
  ///
  /// In en, this message translates to:
  /// **'Counters do not sit idle waiting for absent citizens. When an online appointment holder is absent, waiting physical walk-in citizens may be served according to fair dispatch rules.'**
  String get policyNoShowDispatchP2;

  /// No description provided for @policyTroubleshootingTitle.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting (What Should I Do?)'**
  String get policyTroubleshootingTitle;

  /// No description provided for @policyTroubleshootingP1.
  ///
  /// In en, this message translates to:
  /// **'Forgot documents: Counter officers cannot process incomplete applications. You will need to cancel and book again once original documents are ready.'**
  String get policyTroubleshootingP1;

  /// No description provided for @policyTroubleshootingP2.
  ///
  /// In en, this message translates to:
  /// **'Booked wrong service: Cancel the active appointment in the app and immediately select the correct service from the directory.'**
  String get policyTroubleshootingP2;

  /// No description provided for @policyTroubleshootingP3.
  ///
  /// In en, this message translates to:
  /// **'System or network issue: Refresh your active token screen or seek immediate assistance at the Civic Centre Help Desk.'**
  String get policyTroubleshootingP3;

  /// No description provided for @policyTroubleshootingP4.
  ///
  /// In en, this message translates to:
  /// **'Need help? Call the official toll-free citizen helpline: 1800-233-5500 (8:00 AM – 8:00 PM).'**
  String get policyTroubleshootingP4;

  /// No description provided for @policyMultipleServicesDuplicatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple Services & Duplicate Bookings'**
  String get policyMultipleServicesDuplicatesTitle;

  /// No description provided for @policyMultipleServicesDuplicatesP1.
  ///
  /// In en, this message translates to:
  /// **'Different services are handled by specialized counters. If you require multiple distinct civic services, each must be booked separately.'**
  String get policyMultipleServicesDuplicatesP1;

  /// No description provided for @policyMultipleServicesDuplicatesP2.
  ///
  /// In en, this message translates to:
  /// **'Unified multi-service family bundles are not currently supported by the system.'**
  String get policyMultipleServicesDuplicatesP2;

  /// No description provided for @policyMultipleServicesDuplicatesP3.
  ///
  /// In en, this message translates to:
  /// **'Duplicate booking prevention: QueueLess allows only one active token per phone number for the same service on the same date. Attempting a second active booking is blocked.'**
  String get policyMultipleServicesDuplicatesP3;

  /// No description provided for @policyFamilyGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Family & Group Booking Rules'**
  String get policyFamilyGroupTitle;

  /// No description provided for @policyFamilyGroupP1.
  ///
  /// In en, this message translates to:
  /// **'A citizen can book on behalf of family members by specifying the group size (1 to 5+ people) during booking.'**
  String get policyFamilyGroupP1;

  /// No description provided for @policyFamilyGroupP2.
  ///
  /// In en, this message translates to:
  /// **'The selected party size must represent the people who will actually attend the civic centre together.'**
  String get policyFamilyGroupP2;

  /// No description provided for @policyFamilyGroupP3.
  ///
  /// In en, this message translates to:
  /// **'When completing the service, the officer records the exact count of people who were actually served.'**
  String get policyFamilyGroupP3;

  /// No description provided for @policyPhysicalWalkinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Physical Walk-In Citizens (No Smartphone)'**
  String get policyPhysicalWalkinsTitle;

  /// No description provided for @policyPhysicalWalkinsP1.
  ///
  /// In en, this message translates to:
  /// **'Citizens who do not have a smartphone or internet access can visit the Civic Centre Help Desk in person.'**
  String get policyPhysicalWalkinsP1;

  /// No description provided for @policyPhysicalWalkinsP2.
  ///
  /// In en, this message translates to:
  /// **'Help desk staff will issue a physical paper token (e.g. P-001) printed with an estimated turn time.'**
  String get policyPhysicalWalkinsP2;

  /// No description provided for @policyPhysicalWalkinsP3.
  ///
  /// In en, this message translates to:
  /// **'Physical walk-in citizens join the same unified queue and are served fairly alongside online appointments.'**
  String get policyPhysicalWalkinsP3;

  /// No description provided for @policyPriorityAssistanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Priority Assistance Policy'**
  String get policyPriorityAssistanceTitle;

  /// No description provided for @policyPriorityAssistanceP1.
  ///
  /// In en, this message translates to:
  /// **'Online booking no longer allows self-selecting priority access, ensuring fair queue access for all citizens.'**
  String get policyPriorityAssistanceP1;

  /// No description provided for @policyPriorityAssistanceP2.
  ///
  /// In en, this message translates to:
  /// **'Eligible citizens (seniors aged 60+, pregnant women, and persons with disabilities) receive priority verification in person at the Help Desk or counter upon showing valid proof.'**
  String get policyPriorityAssistanceP2;

  /// No description provided for @helpAndRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Rules'**
  String get helpAndRulesTitle;

  /// No description provided for @helpAndRulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Important information about appointments, arrival, cancellation and service.'**
  String get helpAndRulesSubtitle;

  /// No description provided for @helpAndRulesAction.
  ///
  /// In en, this message translates to:
  /// **'Help & Rules'**
  String get helpAndRulesAction;

  /// No description provided for @helpAndPoliciesSection.
  ///
  /// In en, this message translates to:
  /// **'Help & Policies'**
  String get helpAndPoliciesSection;

  /// No description provided for @viewAppointmentRulesAction.
  ///
  /// In en, this message translates to:
  /// **'View appointment & cancellation rules'**
  String get viewAppointmentRulesAction;

  /// No description provided for @importantCivicNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Notice'**
  String get importantCivicNoticeTitle;

  /// No description provided for @importantCivicNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'QueueLess helps manage appointments and queues. Final service decisions, document acceptance, eligibility, government deadlines, and official closures remain under the responsibility of the concerned civic authority.'**
  String get importantCivicNoticeBody;

  /// No description provided for @categoryBookingRules.
  ///
  /// In en, this message translates to:
  /// **'1. Booking Rules'**
  String get categoryBookingRules;

  /// No description provided for @categoryArrivalService.
  ///
  /// In en, this message translates to:
  /// **'2. Arrival & Service Delivery'**
  String get categoryArrivalService;

  /// No description provided for @categoryChangesDelays.
  ///
  /// In en, this message translates to:
  /// **'3. Problems & What To Do'**
  String get categoryChangesDelays;

  /// No description provided for @categorySpecialRules.
  ///
  /// In en, this message translates to:
  /// **'4. Special Categories & System Rules'**
  String get categorySpecialRules;

  /// No description provided for @secHowAppointmentsWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'How QueueLess Appointments Work'**
  String get secHowAppointmentsWorkTitle;

  /// No description provided for @secHowAppointmentsWorkP1.
  ///
  /// In en, this message translates to:
  /// **'To schedule a civic service: Select your city, choose your nearest civic centre, and pick the required municipal service.'**
  String get secHowAppointmentsWorkP1;

  /// No description provided for @secHowAppointmentsWorkP2.
  ///
  /// In en, this message translates to:
  /// **'Review the required document checklist and confirm all originals are ready. Then pick an available working date and fixed time slot.'**
  String get secHowAppointmentsWorkP2;

  /// No description provided for @secHowAppointmentsWorkP3.
  ///
  /// In en, this message translates to:
  /// **'Select the number of people coming (1 to 5+), confirm your booking, and receive an instant token confirmation with your assigned date and time window.'**
  String get secHowAppointmentsWorkP3;

  /// No description provided for @secHowAppointmentsWorkP4.
  ///
  /// In en, this message translates to:
  /// **'QueueLess appointments use fixed time slots. You must arrive at the civic centre according to your booked slot.'**
  String get secHowAppointmentsWorkP4;

  /// No description provided for @secAppointmentConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmation Details'**
  String get secAppointmentConfirmationTitle;

  /// No description provided for @secAppointmentConfirmationP1.
  ///
  /// In en, this message translates to:
  /// **'Upon booking, your confirmation displays: Appointment date, fixed time slot, civic centre location, service type, party size, token code, and fee tier.'**
  String get secAppointmentConfirmationP1;

  /// No description provided for @secAppointmentConfirmationP2.
  ///
  /// In en, this message translates to:
  /// **'Confirmation registers your appointment in the system. It does not guarantee that the government office will never experience operational delays or emergency closures.'**
  String get secAppointmentConfirmationP2;

  /// No description provided for @secRequiredDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Required Document Checklist'**
  String get secRequiredDocumentsTitle;

  /// No description provided for @secRequiredDocumentsP1.
  ///
  /// In en, this message translates to:
  /// **'Every municipal service specifies mandatory required documents. Review this checklist carefully before scheduling.'**
  String get secRequiredDocumentsP1;

  /// No description provided for @secRequiredDocumentsP2.
  ///
  /// In en, this message translates to:
  /// **'The confirmation checkbox confirms you have all original documents and copies ready in hand. The app does not electronically verify documents.'**
  String get secRequiredDocumentsP2;

  /// No description provided for @secRequiredDocumentsP3.
  ///
  /// In en, this message translates to:
  /// **'Visiting with missing or invalid documents will result in the counter officer being unable to deliver the service.'**
  String get secRequiredDocumentsP3;

  /// No description provided for @secSlotFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom & Future Appointment Fees'**
  String get secSlotFeesTitle;

  /// No description provided for @secSlotFeesP1.
  ///
  /// In en, this message translates to:
  /// **'Standard appointment slots within 2 days carry a standard fee of ₹20.'**
  String get secSlotFeesP1;

  /// No description provided for @secSlotFeesP2.
  ///
  /// In en, this message translates to:
  /// **'Custom advance slots (3+ days ahead) display a ₹50 slot fee in the app. All fees are currently system-simulated for demonstration; no real money is deducted.'**
  String get secSlotFeesP2;

  /// No description provided for @secSlotFeesP3.
  ///
  /// In en, this message translates to:
  /// **'A fee never buys priority over other citizens and never guarantees service. It does not protect against official closures or system downtime.'**
  String get secSlotFeesP3;

  /// No description provided for @secAdvanceDeadlinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Advance Booking & Government Deadlines'**
  String get secAdvanceDeadlinesTitle;

  /// No description provided for @secAdvanceDeadlinesP1.
  ///
  /// In en, this message translates to:
  /// **'The civic department or administrator may close online advance booking ahead of official government deadlines or holiday periods.'**
  String get secAdvanceDeadlinesP1;

  /// No description provided for @secAdvanceDeadlinesP2.
  ///
  /// In en, this message translates to:
  /// **'When online booking is closed for a service, citizens must visit the civic centre in person and follow the physical counter process.'**
  String get secAdvanceDeadlinesP2;

  /// No description provided for @secArrivalCheckinTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrival & Entrance QR Check-In'**
  String get secArrivalCheckinTitle;

  /// No description provided for @secArrivalCheckinP1.
  ///
  /// In en, this message translates to:
  /// **'Arrive at the civic centre on time for your scheduled appointment slot.'**
  String get secArrivalCheckinP1;

  /// No description provided for @secArrivalCheckinP2.
  ///
  /// In en, this message translates to:
  /// **'Upon entering the building, scan the official entrance QR code with your app to confirm physical presence.'**
  String get secArrivalCheckinP2;

  /// No description provided for @secArrivalCheckinP3.
  ///
  /// In en, this message translates to:
  /// **'Remote, premature, or invalid QR scans are rejected. Live queue position and waiting ahead count become active once you arrive.'**
  String get secArrivalCheckinP3;

  /// No description provided for @secOnMyWayTitle.
  ///
  /// In en, this message translates to:
  /// **'\"I\'m On My Way\" (+5 Minutes Extension)'**
  String get secOnMyWayTitle;

  /// No description provided for @secOnMyWayP1.
  ///
  /// In en, this message translates to:
  /// **'If briefly delayed in transit, tap \"I\'m On My Way\" while your token is in Waiting or Called status.'**
  String get secOnMyWayP1;

  /// No description provided for @secOnMyWayP2.
  ///
  /// In en, this message translates to:
  /// **'This feature provides a one-time 5-minute extension to your arrival grace buffer.'**
  String get secOnMyWayP2;

  /// No description provided for @secOnMyWayP3.
  ///
  /// In en, this message translates to:
  /// **'It cannot be repeatedly claimed, does not change your original slot time, and does not guarantee immediate counter service upon arrival.'**
  String get secOnMyWayP3;

  /// No description provided for @secIfLateTitle.
  ///
  /// In en, this message translates to:
  /// **'If I Am Late'**
  String get secIfLateTitle;

  /// No description provided for @secIfLateP1.
  ///
  /// In en, this message translates to:
  /// **'If you are running late, still proceed to the civic centre as quickly as possible.'**
  String get secIfLateP1;

  /// No description provided for @secIfLateP2.
  ///
  /// In en, this message translates to:
  /// **'If you fail to arrive within the grace window, the officer may call another waiting citizen to keep counters productive.'**
  String get secIfLateP2;

  /// No description provided for @secIfLateP3.
  ///
  /// In en, this message translates to:
  /// **'Being late does not automatically push your appointment forward to a later time.'**
  String get secIfLateP3;

  /// No description provided for @secNoShowTitle.
  ///
  /// In en, this message translates to:
  /// **'No-Show & Fair Dispatch'**
  String get secNoShowTitle;

  /// No description provided for @secNoShowP1.
  ///
  /// In en, this message translates to:
  /// **'If an online appointment holder does not check in within the grace window, the counter officer manually calls the next eligible citizen.'**
  String get secNoShowP1;

  /// No description provided for @secNoShowP2.
  ///
  /// In en, this message translates to:
  /// **'Waiting physical walk-in citizens may be served during unused capacity so government staff do not sit idle.'**
  String get secNoShowP2;

  /// No description provided for @secServiceCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Completion & Double-Confirmation'**
  String get secServiceCompletionTitle;

  /// No description provided for @secServiceCompletionP1.
  ///
  /// In en, this message translates to:
  /// **'At the counter, the officer examines physical documents and records the service outcome (Successful, Partial, or Missing Documents).'**
  String get secServiceCompletionP1;

  /// No description provided for @secServiceCompletionP2.
  ///
  /// In en, this message translates to:
  /// **'For online appointments, a double-confirmation prompt appears in your mobile app so you can verify that service delivery occurred.'**
  String get secServiceCompletionP2;

  /// No description provided for @secRatingFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Rating & Citizen Feedback'**
  String get secRatingFeedbackTitle;

  /// No description provided for @secRatingFeedbackP1.
  ///
  /// In en, this message translates to:
  /// **'After confirming service completion, you can submit a 1 to 5 star rating and optional comments.'**
  String get secRatingFeedbackP1;

  /// No description provided for @secRatingFeedbackP2.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps the department improve civic service quality. Feedback does not impact queue priority or future bookings.'**
  String get secRatingFeedbackP2;

  /// No description provided for @secCancellationRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Rules'**
  String get secCancellationRulesTitle;

  /// No description provided for @secCancellationRulesP1.
  ///
  /// In en, this message translates to:
  /// **'You may cancel your appointment from the app anytime while your token is in Waiting or Called status before service starts.'**
  String get secCancellationRulesP1;

  /// No description provided for @secCancellationRulesP2.
  ///
  /// In en, this message translates to:
  /// **'Once the counter officer begins serving you (Serving status) or after service completion, cancellation is no longer permitted.'**
  String get secCancellationRulesP2;

  /// No description provided for @secCancellationRulesP3.
  ///
  /// In en, this message translates to:
  /// **'QueueLess charges no cancellation fees or penalties for cancelling an active appointment.'**
  String get secCancellationRulesP3;

  /// No description provided for @secReschedulingPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Rescheduling Policy'**
  String get secReschedulingPolicyTitle;

  /// No description provided for @secReschedulingPolicyP1.
  ///
  /// In en, this message translates to:
  /// **'Self-service automatic rescheduling is currently NOT available in the system.'**
  String get secReschedulingPolicyP1;

  /// No description provided for @secReschedulingPolicyP2.
  ///
  /// In en, this message translates to:
  /// **'If you cannot attend, cancel your active token in the app and book a fresh available slot for another day or time.'**
  String get secReschedulingPolicyP2;

  /// No description provided for @secOfficeDelaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Government & Office Delays'**
  String get secOfficeDelaysTitle;

  /// No description provided for @secOfficeDelaysP1.
  ///
  /// In en, this message translates to:
  /// **'If the government office, counter, department network, or biometric system causes a delay, the citizen is not held responsible.'**
  String get secOfficeDelaysP1;

  /// No description provided for @secOfficeDelaysP2.
  ///
  /// In en, this message translates to:
  /// **'Your booked slot does not silently shift. The app displays real-time delay notices and queue status. Please follow in-office guidance.'**
  String get secOfficeDelaysP2;

  /// No description provided for @secOfficeClosuresTitle.
  ///
  /// In en, this message translates to:
  /// **'Civic Centre & Counter Closures'**
  String get secOfficeClosuresTitle;

  /// No description provided for @secOfficeClosuresP1.
  ///
  /// In en, this message translates to:
  /// **'A civic centre, service, or counter may close temporarily due to an emergency, administrative order, or gazetted holiday.'**
  String get secOfficeClosuresP1;

  /// No description provided for @secOfficeClosuresP2.
  ///
  /// In en, this message translates to:
  /// **'When closed, new bookings are blocked. Premium or custom appointment fees do not guarantee service during official closures.'**
  String get secOfficeClosuresP2;

  /// No description provided for @secServerFailuresTitle.
  ///
  /// In en, this message translates to:
  /// **'Server & Technical Outages'**
  String get secServerFailuresTitle;

  /// No description provided for @secServerFailuresP1.
  ///
  /// In en, this message translates to:
  /// **'If a service or counter encounters technical issues, the office administrator may pause the affected queue while others continue.'**
  String get secServerFailuresP1;

  /// No description provided for @secServerFailuresP2.
  ///
  /// In en, this message translates to:
  /// **'Automatic rescheduling for prolonged outages is not currently available. Please follow the instructions provided by the civic centre.'**
  String get secServerFailuresP2;

  /// No description provided for @secTroubleshootingTitle.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting (What To Do If Something Goes Wrong)'**
  String get secTroubleshootingTitle;

  /// No description provided for @secTroubleshootingP1.
  ///
  /// In en, this message translates to:
  /// **'Appointment not showing: Ensure you are logged in with the mobile number used during booking and pull down to refresh.'**
  String get secTroubleshootingP1;

  /// No description provided for @secTroubleshootingP2.
  ///
  /// In en, this message translates to:
  /// **'Cannot check in or QR failing: Verify camera permissions and ensure you are scanning the official QR displayed at the entrance.'**
  String get secTroubleshootingP2;

  /// No description provided for @secTroubleshootingP3.
  ///
  /// In en, this message translates to:
  /// **'Required document missing: Cancel your active token and re-book after obtaining all required original documents.'**
  String get secTroubleshootingP3;

  /// No description provided for @secTroubleshootingP4.
  ///
  /// In en, this message translates to:
  /// **'Office delayed or counter closed: Check the live app queue status and consult the civic centre Help Desk.'**
  String get secTroubleshootingP4;

  /// No description provided for @secTroubleshootingP5.
  ///
  /// In en, this message translates to:
  /// **'Duplicate booking message: You already hold an active token for this service today; complete or cancel it before booking again.'**
  String get secTroubleshootingP5;

  /// No description provided for @secTroubleshootingP6.
  ///
  /// In en, this message translates to:
  /// **'Citizen Helpline: For urgent questions, call the official toll-free helpline: 1800-233-5500 (8:00 AM – 8:00 PM).'**
  String get secTroubleshootingP6;

  /// No description provided for @secFamilyGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Family & Group Bookings'**
  String get secFamilyGroupTitle;

  /// No description provided for @secFamilyGroupP1.
  ///
  /// In en, this message translates to:
  /// **'One citizen can book on behalf of family members by selecting group size (1 to 4 people).'**
  String get secFamilyGroupP1;

  /// No description provided for @secFamilyGroupP2.
  ///
  /// In en, this message translates to:
  /// **'All group members must attend together with their respective required documents. The officer records the count of persons actually served.'**
  String get secFamilyGroupP2;

  /// No description provided for @secFamilyGroupP3.
  ///
  /// In en, this message translates to:
  /// **'One booking does not create a multi-service bundle; it covers the selected service only.'**
  String get secFamilyGroupP3;

  /// No description provided for @secMultipleServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple Services Booking'**
  String get secMultipleServicesTitle;

  /// No description provided for @secMultipleServicesP1.
  ///
  /// In en, this message translates to:
  /// **'Different municipal services are handled by distinct specialized counters.'**
  String get secMultipleServicesP1;

  /// No description provided for @secMultipleServicesP2.
  ///
  /// In en, this message translates to:
  /// **'If you require multiple separate services, you must make a separate booking for each service.'**
  String get secMultipleServicesP2;

  /// No description provided for @secDuplicateBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Booking Prevention'**
  String get secDuplicateBookingTitle;

  /// No description provided for @secDuplicateBookingP1.
  ///
  /// In en, this message translates to:
  /// **'QueueLess strictly prevents duplicate active bookings for the same citizen/phone for the same service on the same date.'**
  String get secDuplicateBookingP1;

  /// No description provided for @secDuplicateBookingP2.
  ///
  /// In en, this message translates to:
  /// **'You cannot hold two concurrent active tokens for the same service. Cancel your existing booking first if you need to change times.'**
  String get secDuplicateBookingP2;

  /// No description provided for @secPhysicalWalkinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Physical Walk-In Citizens (Help Desk)'**
  String get secPhysicalWalkinsTitle;

  /// No description provided for @secPhysicalWalkinsP1.
  ///
  /// In en, this message translates to:
  /// **'Citizens without a smartphone or internet access can visit the civic centre Help Desk in person.'**
  String get secPhysicalWalkinsP1;

  /// No description provided for @secPhysicalWalkinsP2.
  ///
  /// In en, this message translates to:
  /// **'Help desk staff generate a physical paper token (e.g. P-001) printed with an estimated turn time.'**
  String get secPhysicalWalkinsP2;

  /// No description provided for @secPhysicalWalkinsP3.
  ///
  /// In en, this message translates to:
  /// **'Physical and online citizens share the same operational queue and are dispatched fairly by counter officers.'**
  String get secPhysicalWalkinsP3;

  /// No description provided for @secPriorityCitizensTitle.
  ///
  /// In en, this message translates to:
  /// **'Priority Assistance Eligibility'**
  String get secPriorityCitizensTitle;

  /// No description provided for @secPriorityCitizensP1.
  ///
  /// In en, this message translates to:
  /// **'Priority access is reserved for senior citizens (60+), pregnant women, and persons with disabilities (PwD).'**
  String get secPriorityCitizensP1;

  /// No description provided for @secPriorityCitizensP2.
  ///
  /// In en, this message translates to:
  /// **'Online booking does not allow self-selecting priority access. Eligibility is verified in-person at the Help Desk or counter upon showing valid proof.'**
  String get secPriorityCitizensP2;

  /// No description provided for @secPrivacyDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Lobby Display Policy'**
  String get secPrivacyDisplayTitle;

  /// No description provided for @secPrivacyDisplayP1.
  ///
  /// In en, this message translates to:
  /// **'Public TV and counter displays show token display codes only (e.g. TAX-001 at Counter 2).'**
  String get secPrivacyDisplayP1;

  /// No description provided for @secPrivacyDisplayP2.
  ///
  /// In en, this message translates to:
  /// **'Citizen names, phone numbers, and identity documents are never displayed publicly. Keep your registered phone secure.'**
  String get secPrivacyDisplayP2;

  /// No description provided for @showVerificationCodeToOfficer.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to the counter officer or provide your 6-digit verification code before service starts.'**
  String get showVerificationCodeToOfficer;

  /// No description provided for @counterVerificationSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get counterVerificationSecretLabel;

  /// No description provided for @secCounterVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Mandatory Counter Token Verification'**
  String get secCounterVerificationTitle;

  /// No description provided for @secCounterVerificationP1.
  ///
  /// In en, this message translates to:
  /// **'Before beginning service, the counter officer must verify your token. Service cannot begin simply because your token was called.'**
  String get secCounterVerificationP1;

  /// No description provided for @secCounterVerificationP2.
  ///
  /// In en, this message translates to:
  /// **'Provide the 6-digit verification code or show the QR code displayed on your app screen (or on your printed Turn Slip). The public token code shown on lobby screens cannot be used for verification.'**
  String get secCounterVerificationP2;

  /// No description provided for @secCounterVerificationP3.
  ///
  /// In en, this message translates to:
  /// **'Verification secrets are single-use and bound to your assigned counter. If you lose your slip or phone, an authorized officer can apply a logged administrative override with an official reason.'**
  String get secCounterVerificationP3;

  /// No description provided for @accompanyingPersonsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Accompanying Persons Details (Max 4 Total)'**
  String get accompanyingPersonsSectionTitle;

  /// No description provided for @sameCounterOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Single Counter Policy: All accompanying members must attend for this same counter service. Any person needing work at another counter or department must book a separate appointment.'**
  String get sameCounterOnlyNotice;

  /// No description provided for @personIndexLabel.
  ///
  /// In en, this message translates to:
  /// **'Accompanying Person #{number}'**
  String personIndexLabel(int number);

  /// No description provided for @accompanyingPersonNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name (as per identity proof)'**
  String get accompanyingPersonNameHint;

  /// No description provided for @coAttendanceReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for Co-Attendance at this Counter'**
  String get coAttendanceReasonLabel;

  /// No description provided for @selectCoAttendanceReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select valid reason for this counter'**
  String get selectCoAttendanceReasonPrompt;

  /// No description provided for @reasonJointApplicant.
  ///
  /// In en, this message translates to:
  /// **'Joint Property Owner / Co-applicant for this service'**
  String get reasonJointApplicant;

  /// No description provided for @reasonAssistance.
  ///
  /// In en, this message translates to:
  /// **'Assistance for Senior Citizen / Differently-Abled applicant'**
  String get reasonAssistance;

  /// No description provided for @reasonGuardian.
  ///
  /// In en, this message translates to:
  /// **'Legal Guardian / Authorized Representative'**
  String get reasonGuardian;

  /// No description provided for @reasonWitnessSignatory.
  ///
  /// In en, this message translates to:
  /// **'Witness / Deponent / Signatory for document verification'**
  String get reasonWitnessSignatory;

  /// No description provided for @reasonFamilyVerification.
  ///
  /// In en, this message translates to:
  /// **'Family member required for joint identity verification'**
  String get reasonFamilyVerification;

  /// No description provided for @reasonOtherCounterWork.
  ///
  /// In en, this message translates to:
  /// **'Work at a different counter/department (Separate booking required)'**
  String get reasonOtherCounterWork;

  /// No description provided for @invalidCounterReasonError.
  ///
  /// In en, this message translates to:
  /// **'Not allowed: Accompanying person has work at another counter. Please book a separate appointment for that counter.'**
  String get invalidCounterReasonError;

  /// No description provided for @missingAccompanyingDetailsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please provide full name and select a valid counter reason for all accompanying persons.'**
  String get missingAccompanyingDetailsPrompt;

  /// No description provided for @accompanyingPersonsSummary.
  ///
  /// In en, this message translates to:
  /// **'Accompanying Persons:'**
  String get accompanyingPersonsSummary;

  /// No description provided for @allottedSlotTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Allotted Queue Time'**
  String get allottedSlotTimeLabel;

  /// No description provided for @allottedTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Allotted Tokens & Queue Times'**
  String get allottedTokensTitle;

  /// No description provided for @distinctTokensNotice.
  ///
  /// In en, this message translates to:
  /// **'Each member is allotted their own individual token number and scheduled time in the counter queue.'**
  String get distinctTokensNotice;

  /// No description provided for @queueSlotsReservedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} queue slots will be allotted for your group.'**
  String queueSlotsReservedCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
