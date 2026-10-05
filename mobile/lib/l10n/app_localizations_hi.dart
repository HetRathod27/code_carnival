// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'QueueLess';

  @override
  String get welcomeTitle => 'सरकारी सेवा अपॉइंटमेंट बुकिंग';

  @override
  String get welcomeSubtitle =>
      'निश्चित समय बुक करें, लाइव बारी ट्रैक करें और कतार में खड़े होने से बचें।';

  @override
  String get selectLanguage => 'अपनी भाषा चुनें';

  @override
  String get english => 'English (अंग्रेज़ी)';

  @override
  String get gujarati => 'ગુજરાતી (गुजराती)';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get continueButton => 'आगे बढ़ें';

  @override
  String get loginTitle => 'मोबाइल नंबर से साइन इन करें';

  @override
  String get loginSubtitle =>
      'सत्यापन OTP प्राप्त करने के लिए अपना मोबाइल नंबर दर्ज करें।';

  @override
  String get phoneNumber => 'मोबाइल नंबर';

  @override
  String get enterOtp => '६ अंकों का OTP दर्ज करें';

  @override
  String get sendOtp => 'सत्यापन कोड भेजें';

  @override
  String get verifyOtp => 'सत्यापित करें और आगे बढ़ें';

  @override
  String get browseOffices => 'नागरिक सेवा केंद्र चुनें';

  @override
  String get browseServices => 'सरकारी सेवा चुनें';

  @override
  String get requiredDocuments => 'आवश्यक दस्तावेज़';

  @override
  String get confirmDocumentsPrompt =>
      'मैं पुष्टि करता हूँ कि मेरे पास इस सेवा हेतु सभी आवश्यक मूल दस्तावेज़ तैयार हैं।';

  @override
  String get bookSlot => 'निश्चित अपॉइंटमेंट बुक करें';

  @override
  String get familyCount => 'साथ आने वाले लोगों की संख्या';

  @override
  String get myToken => 'मेरा सक्रिय टोकन';

  @override
  String get appointmentTime => 'अपॉइंटमेंट समय';

  @override
  String get estimatedTurn => 'अनुमानित बारी समय';

  @override
  String get nowServing => 'अभी सेवा';

  @override
  String get waitingAhead => 'आगे प्रतीक्षारत लोग';

  @override
  String get checkInQr => 'उपस्थिति चेक-इन';

  @override
  String get scanEntranceQr =>
      'आगमन की पुष्टि के लिए प्रवेश द्वार QR स्कैन करें';

  @override
  String get cancelAppointment => 'अपॉइंटमेंट रद्द करें';

  @override
  String get confirmCompletion => 'सेवा पूर्ण होने की पुष्टि करें';

  @override
  String get leaveNowAlert => 'अभी निकलें: आपकी बारी निकट आ रही है!';

  @override
  String get doubleConfirmationPrompt =>
      'अधिकारी ने सेवा पूर्ण चिह्नित की है। कृपया पुष्टि करें:';

  @override
  String get serviceCompleted => 'सेवा सफलतापूर्वक पूर्ण हुई';

  @override
  String get officesTitle => 'नागरिक सेवा केंद्र';

  @override
  String get servicesTitle => 'उपलब्ध सेवाएं';

  @override
  String get selectOfficePrompt =>
      'अपना निकटतम नगर पालिका या वार्ड कार्यालय चुनें।';

  @override
  String get selectServicePrompt =>
      'वह नागरिक सेवा चुनें जिसकी आपको आवश्यकता है।';

  @override
  String get noOfficesFound => 'वर्तमान में कोई केंद्र उपलब्ध नहीं है।';

  @override
  String get noServicesFound => 'इस केंद्र पर कोई सेवा उपलब्ध नहीं है।';

  @override
  String get documentChecklistTitle => 'आवश्यक दस्तावेज़ सूची';

  @override
  String get documentChecklistSubtitle =>
      'कार्यालय जाने से पहले कृपया सुनिश्चित करें कि आपके पास निम्नलिखित मूल दस्तावेज़ और प्रतियां उपलब्ध हैं:';

  @override
  String get categorySelectionTitle => 'बुकिंग श्रेणी';

  @override
  String get categoryNormalLabel => 'सामान्य नागरिक';

  @override
  String get categoryPriorityLabel => 'प्राथमिकता सेवा';

  @override
  String get categoryPriorityNotice =>
      'वरिष्ठ नागरिकों (६०+), गर्भवती महिलाओं और दिव्यांगजनों के लिए। आगमन पर मान्य प्रमाण पत्र आवश्यक है।';

  @override
  String get beneficiaryNameLabel => 'लाभार्थी का नाम (वैकल्पिक)';

  @override
  String get beneficiaryNameHint => 'सेवा प्राप्त करने वाले व्यक्ति का नाम';

  @override
  String get bookAppointmentAction => 'निश्चित अपॉइंटमेंट बुक करें';

  @override
  String get bookingConfirmationTitle => 'अपॉइंटमेंट सफलतापूर्वक दर्ज हुआ!';

  @override
  String get bookingSuccessMessage =>
      'आपका टोकन तैयार है। त्वरित सेवा सुनिश्चित करने के लिए समय पर पहुंचे।';

  @override
  String get viewTokenAction => 'मेरा टोकन देखें';

  @override
  String get onlineAlternativeNotice =>
      'यह सेवा कार्यालय आए बिना ऑनलाइन भी उपलब्ध है! आप सीधे आधिकारिक पोर्टल का उपयोग कर सकते हैं।';

  @override
  String get openOnlineLink => 'ऑनलाइन पोर्टल खोलें';

  @override
  String get avgServiceDuration => 'औसत सेवा समय';

  @override
  String get currentQueueWait => 'वर्तमान कतार प्रतीक्षा';

  @override
  String get minutesUnit => 'मिनट';

  @override
  String get retryAction => 'पुनः प्रयास करें';

  @override
  String get officeHoursLabel => 'कार्यालय समय';

  @override
  String get onMyWayAction => 'मैं रास्ते में हूँ (+५ मिनट)';

  @override
  String get onMyWaySuccess => 'अतिरिक्त ५ मिनट की छूट मिल गई है!';

  @override
  String get onMyWayClaimed => 'समय विस्तार लिया जा चुका है';

  @override
  String get presenceVerified => 'कार्यालय में उपस्थिति सत्यापित';

  @override
  String get enterQrCodePrompt => 'प्रवेश द्वार QR कोड दर्ज करें या स्कैन करें';

  @override
  String get confirmCancelPrompt =>
      'क्या आप वाकई इस अपॉइंटमेंट को रद्द करना चाहते हैं?';

  @override
  String get cancelReasonLabel => 'रद्द करने का कारण (वैकल्पिक)';

  @override
  String get etaRangePrefix => 'अनुमानित बारी विंडो:';

  @override
  String get nowServingAt => 'वर्तमान में सेवा:';
}
