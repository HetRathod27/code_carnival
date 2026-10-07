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
  /// **'Currently Serving:'**
  String get nowServingAt;

  /// No description provided for @chooseDateTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Choose Date & Time Slot'**
  String get chooseDateTimeSlot;

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
  /// **'Within 2 Days • ₹0 Fee'**
  String get within2DaysFeeFree;

  /// No description provided for @customDateFee50.
  ///
  /// In en, this message translates to:
  /// **'Custom Date • ₹50 Fee'**
  String get customDateFee50;

  /// No description provided for @normalSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal Slot (Within 2 Days) • Free / ₹0 Standard Fee'**
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
  /// **'Standard near-term booking within 2 days carries no additional fee.'**
  String get standardNearTermNotice;

  /// No description provided for @availableTimeSlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Time Slots'**
  String get availableTimeSlotsTitle;

  /// No description provided for @slotsFullWarning.
  ///
  /// In en, this message translates to:
  /// **'Slots are full for this time! Please select another available slot or another day. Booking any available normal slot within 2 days carries zero extra fees.'**
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
  /// **'Confirm Appointment • Standard Fee: ₹0'**
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
  /// **'Standard / Free (₹0)'**
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
