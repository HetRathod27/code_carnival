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
}
