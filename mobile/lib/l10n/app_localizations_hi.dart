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
  String get checkAllDocsFirstNotice =>
      'कृपया पहले ऊपर दिए गए प्रत्येक आवश्यक दस्तावेज़ का चयन करें।';

  @override
  String docsVerifiedProgress(int checked, int total) {
    return '$total में से $checked चयनित';
  }

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
  String get yourTurnIsNext => 'आपकी बारी अब अगली है! (~१ मि)';

  @override
  String get appointmentSlotLabel => 'अपॉइंटमेंट स्लॉट';

  @override
  String get counterClosedBadge => 'काउंटर बंद है';

  @override
  String get counterClosedNotice =>
      'काउंटर बंद होने के कारण अपॉइंटमेंट अस्थायी रूप से अनुपलब्ध हैं।';

  @override
  String get counterOnBreakBadge => 'काउंटर ब्रेक पर है';

  @override
  String get counterOnBreakNotice =>
      'काउंटर ब्रेक पर होने के कारण अपॉइंटमेंट अस्थायी रूप से अनुपलब्ध हैं।';

  @override
  String get nowServingAt => 'वर्तमान में सेवा:';

  @override
  String get chooseDateTimeSlot => 'उपलब्ध अपॉइंटमेंट स्लॉट चुनें';

  @override
  String get chooseAvailableSlotInstruction =>
      'नीचे दिए गए समय सारिणी में से उपलब्ध निश्चित अपॉइंटमेंट स्लॉट चुनें।';

  @override
  String get selectedDateLabel => 'चुनी गई तारीख';

  @override
  String get openCalendarAction => 'कैलेंडर खोलें';

  @override
  String get quickSelectionTitle => 'त्वरित चयन';

  @override
  String get todayLabel => 'आज';

  @override
  String get tomorrowLabel => 'कल';

  @override
  String get in2DaysLabel => '२ दिनों में';

  @override
  String get in3DaysLabel => '३ दिनों में';

  @override
  String get within2DaysFeeFree => '२ दिनों में • ₹२० शुल्क';

  @override
  String get customDateFee50 => 'कस्टम तारीख • ₹५० शुल्क';

  @override
  String get normalSlotTitle => 'सामान्य स्लॉट (२ दिनों में) • ₹२० मानक शुल्क';

  @override
  String get customSlotTitle => 'कस्टम भविष्य स्लॉट • अतिरिक्त शुल्क (₹५०)';

  @override
  String get statutoryDisclosure =>
      'वैधानिक प्रकटीकरण (नियम ६.३): कस्टम स्लॉट शुल्क आपातकालीन कार्यालय बंद, सार्वजनिक अवकाश या सर्वर विलंब से सुरक्षा प्रदान नहीं करता है।';

  @override
  String get standardNearTermNotice =>
      '२ दिनों के भीतर सामान्य बुकिंग के लिए ₹२० बुकिंग शुल्क लागू है।';

  @override
  String get availableTimeSlotsTitle => 'उपलब्ध समय स्लॉट्स';

  @override
  String get slotsFullWarning =>
      'इस समय के लिए स्लॉट भर चुके हैं! कृपया अन्य उपलब्ध स्लॉट या अन्य दिन चुनें। २ दिनों में उपलब्ध किसी भी सामान्य स्लॉट के लिए ₹२० मानक शुल्क लागू है।';

  @override
  String get slotsFullBadge => 'स्लॉट भर गए';

  @override
  String get availableBadge => 'उपलब्ध';

  @override
  String get peopleCountPrompt => 'आपके साथ कितने लोग आ रहे हैं?';

  @override
  String get confirmAppointmentStandard =>
      'अपॉइंटमेंट पुष्टि करें • मानक शुल्क: ₹२०';

  @override
  String get confirmAppointmentHigher =>
      'अपॉइंटमेंट पुष्टि करें • अतिरिक्त शुल्क: ₹५०';

  @override
  String get applicantDetailsTitle => 'आवेदक का विवरण';

  @override
  String get dateSummaryLabel => 'तारीख:';

  @override
  String get slotTimeSummaryLabel => 'स्लॉट समय:';

  @override
  String get partySizeSummaryLabel => 'व्यक्तियों की संख्या:';

  @override
  String get feeTierSummaryLabel => 'शुल्क श्रेणी:';

  @override
  String get standardFreeTier => 'मानक स्लॉट (₹२०)';

  @override
  String get customPaidTier => 'कस्टम अग्रिम स्लॉट (₹५०)';

  @override
  String get onePerson => '१ व्यक्ति';

  @override
  String multiplePeople(Object count) {
    return '$count लोग';
  }

  @override
  String get signInTitle => 'क्यूबलेस साइन इन';

  @override
  String get enterMobileNumber => 'मोबाइल नंबर दर्ज करें';

  @override
  String get invalidPhoneError => 'कृपया मान्य मोबाइल नंबर दर्ज करें';

  @override
  String get invalidOtpError => 'कृपया 6-अंकीय ओटीपी दर्ज करें';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करें…';

  @override
  String get sendOtpAction => 'सत्यापन कोड प्राप्त करें';

  @override
  String get verifyOtpAction => 'ओटीपी सत्यापित करें और प्रवेश करें';

  @override
  String get otpLabel => '6-अंकीय ओटीपी';

  @override
  String get activeAppointmentBanner => 'सक्रिय अपॉइंटमेंट जारी है';

  @override
  String tapToViewEta(String code) {
    return 'टोकन: $code • लाइव समय देखने के लिए टैप करें';
  }

  @override
  String get priorityAllowedBadge => '⭐ प्राथमिकता मान्य';

  @override
  String get seniorCitizenCategory => 'वरिष्ठ नागरिक (60+ वर्ष)';

  @override
  String get pregnantCategory => 'गर्भवती / धात्री माता';

  @override
  String get disabilityCategory => 'दिव्यांग व्यक्ति (PwD)';

  @override
  String get medicalCategory => 'चिकित्सा आपातकाल / स्वास्थ्य';

  @override
  String get eligibilityCategoryLabel => 'पात्रता श्रेणी';

  @override
  String get signOutTooltip => 'साइन आउट';

  @override
  String get keepAppointmentAction => 'अपॉइंटमेंट जारी रखें';

  @override
  String get yesCancelAction => 'हाँ, रद्द करें';

  @override
  String get cancelSuccessMessage => 'अपॉइंटमेंट सफलतापूर्वक रद्द किया गया';

  @override
  String get priorityBadge => '⭐ प्राथमिकता';

  @override
  String get notCheckedInStatus => 'अभी चेक-इन नहीं किया है';

  @override
  String get calculatingEta => 'गणना की जा रही है…';

  @override
  String get noActiveAppointment => 'कोई सक्रिय अपॉइंटमेंट नहीं है';

  @override
  String get cancelAction => 'रद्द करें';

  @override
  String get verifyArrivalAction => 'आगमन सत्यापित करें';

  @override
  String get qrCodeInstruction =>
      'अपने आगमन के सत्यापन के लिए यह QR कोड प्रवेश अधिकारी या काउंटर स्कैनर को दिखाएं।';

  @override
  String get manualVerificationCodePrompt => 'टोकन सत्यापन कोड';

  @override
  String get qrFallbackOfficerNotice =>
      'यदि QR स्कैनर में कोई समस्या आए तो यह कोड अधिकारी को बताएं।';

  @override
  String get appointmentConfirmedCardTitle => 'अपॉइंटमेंट सुनिश्चित हुआ';

  @override
  String get appointmentFutureNotice =>
      'आपकी अपॉइंटमेंट आगामी तिथि के लिए सुनिश्चित है। कार्यालय खुलने के बाद आपकी अपॉइंटमेंट के दिन लाइव कतार स्थिति सक्रिय होगी।';

  @override
  String get appointmentScheduledFor => 'नियत तिथि एवं समय';

  @override
  String get serviceLabel => 'सरकारी सेवा';

  @override
  String get civicCentreLabel => 'नागरिक सुविधा केंद्र';

  @override
  String get tokenLabel => 'टोकन कोड';

  @override
  String get partySizeLabel => 'साथ आने वाले लोगों की संख्या';

  @override
  String get feeLabel => 'लागू शुल्क';

  @override
  String get feeDemoNotice =>
      'केवल डेमो शुल्क • कोई भुगतान गेटवे जुड़ा नहीं है';

  @override
  String get feeFreeNotice => 'मानक नागरिक अपॉइंटमेंट • ₹२० शुल्क';

  @override
  String get liveQueueActiveNotice => 'सक्रिय कार्यालय कतार ट्रैकिंग';

  @override
  String get officeDelayAlert =>
      'कार्यालय में वर्तमान में सेवा में विलंब हो रहा है। आपका अपॉइंटमेंट समय अपरिवर्तित है, लेकिन सेवा में अपेक्षा से अधिक समय लग सकता है।';

  @override
  String get cancelNotAllowedNotice =>
      'रद्दीकरण की निर्धारित समय-सीमा समाप्त हो चुकी है। यह अपॉइंटमेंट अब ऑनलाइन रद्द नहीं किया जा सकता।';

  @override
  String get searchServicesPlaceholder => 'सेवाएं खोजें';

  @override
  String get searchServicesTooltip => 'सेवाएं खोजें';

  @override
  String get clearSearchTooltip => 'खोज साफ़ करें';

  @override
  String centresOfferService(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count केंद्र यह सेवा प्रदान करते हैं',
      one: '१ केंद्र यह सेवा प्रदान करता है',
    );
    return '$_temp0';
  }

  @override
  String serviceAvailableNotice(String serviceName) {
    return '→ $serviceName उपलब्ध';
  }

  @override
  String get noCentresOfferService =>
      'इस शहर में कोई भी नागरिक केंद्र यह सेवा प्रदान नहीं करता है।';

  @override
  String get clearSearchAction => 'खोज साफ़ करें';

  @override
  String get rulesAndPoliciesTitle => 'नियम और नीतियां';

  @override
  String get rulesAndPoliciesSubtitle =>
      'QueueLess का उपयोग करते समय विभिन्न परिस्थितियों में क्या करें, इसकी मार्गदर्शिका';

  @override
  String get rulesAndPoliciesAction => 'नियम और नीतियां';

  @override
  String get viewAppointmentPoliciesAction => 'अपॉइंटमेंट नीतियां देखें';

  @override
  String get policyFooterHeading =>
      'QueueLess अपॉइंटमेंट और नागरिक सेवा नीतियां';

  @override
  String get policyFooterVersion =>
      'आधिकारिक नागरिक प्रणाली v1.1.0 • गुजरात ई-गवर्नेंस';

  @override
  String get policyTapToExpand => 'नियम देखने के लिए टैप करें';

  @override
  String get policyTapToCollapse => 'बंद करने के लिए टैप करें';

  @override
  String get categoryBooking => '1. अपॉइंटमेंट बुकिंग';

  @override
  String get categoryOnTheDay => '2. विज़िट के दिन';

  @override
  String get categoryChangesProblems => '3. परिवर्तन और समस्या निवारण';

  @override
  String get categorySpecialCases => '4. विशेष श्रेणियां और वॉक-इन';

  @override
  String get policyBookingFlowTitle =>
      'अपॉइंटमेंट बुकिंग और आवश्यक दस्तावेज चेकलिस्ट';

  @override
  String get policyBookingFlowP1 =>
      'अपॉइंटमेंट शेड्यूल करने के लिए, पहले अपना शहर, निकटतम नागरिक सुविधा केंद्र और आवश्यक नगरपालिका सेवा चुनें।';

  @override
  String get policyBookingFlowP2 =>
      'बुकिंग से पहले अनिवार्य दस्तावेज चेकलिस्ट की समीक्षा करें। सभी मूल दस्तावेज तैयार होने की पुष्टि करने के बाद ही बुकिंग बटन सक्रिय होता है।';

  @override
  String get policyBookingFlowP3 =>
      'अपनी पसंदीदा उपलब्ध तिथि (आज, कल या आगामी कार्य दिवस) और एक निश्चित समय स्लॉट चुनें।';

  @override
  String get policyBookingFlowP4 =>
      'साथ आने वाले व्यक्तियों की संख्या (1 से 5+) चुनें। आपकी अपॉइंटमेंट चुनी गई तिथि और समय विंडो से पूरी तरह बंधी होती है।';

  @override
  String get policyConfirmationDetailsTitle => 'अपॉइंटमेंट पुष्टिकरण विवरण';

  @override
  String get policyConfirmationDetailsP1 =>
      'पुष्टि होने पर, आपका टोकन डिस्प्ले कोड (जैसे TAX-001), अपॉइंटमेंट तिथि, निश्चित समय स्लॉट, केंद्र और व्यक्तियों की संख्या दर्ज हो जाएगी।';

  @override
  String get policyConfirmationDetailsP2 =>
      'आपकी अपॉइंटमेंट होम स्क्रीन और लाइव टोकन स्क्रीन पर दिखाई देती है, जो आज के लिए लाइव कतार स्थिति और प्रतीक्षा संख्या दर्शाती है।';

  @override
  String get policyConfirmationDetailsP3 =>
      'केंद्र जाते समय सभी मूल दस्तावेज, प्रतियां और पंजीकृत मोबाइल फोन साथ ले जाना याद रखें।';

  @override
  String get policySlotFeesTitle => 'निश्चित अपॉइंटमेंट स्लॉट और शुल्क नियम';

  @override
  String get policySlotFeesP1 =>
      'QueueLess अपॉइंटमेंट निश्चित स्लॉट हैं। किसी अन्य नागरिक के अनुपस्थित होने पर आपका समय अपने आप नहीं बदला जाता।';

  @override
  String get policySlotFeesP2 =>
      '2 दिनों के भीतर मानक अपॉइंटमेंट के लिए ₹२० मानक शुल्क लागू है (Fee: ₹20)।';

  @override
  String get policySlotFeesP3 =>
      'अग्रिम कस्टम स्लॉट (3+ दिन बाद) ऐप में ₹50 स्लॉट शुल्क दिखाते हैं। वर्तमान में शुल्क केवल डेमो/प्रणाली-अनुरूपित है और कोई वास्तविक कटौती नहीं होती।';

  @override
  String get policySlotFeesP4 =>
      'वैधानिक प्रकटीकरण: बुक किया गया स्लॉट अप्रत्याशित आपातकालीन सरकारी बंदी, सार्वजनिक अवकाश या सर्वर व्यवधान से सुरक्षा की गारंटी नहीं देता।';

  @override
  String get policyArrivalAndCheckinTitle => 'आगमन और भौतिक उपस्थिति चेक-इन';

  @override
  String get policyArrivalAndCheckinP1 =>
      'नागरिकों को निर्धारित समय स्लॉट पर या उससे कुछ समय पहले नागरिक केंद्र पर भौतिक रूप से उपस्थित होना आवश्यक है।';

  @override
  String get policyArrivalAndCheckinP2 =>
      'उपस्थिति सत्यापित करने के लिए ऐप द्वारा प्रवेश द्वार पर आधिकारिक QR कोड स्कैन करें। दूरस्थ या फर्जी चेक-इन पूरी तरह से प्रतिबंधित है।';

  @override
  String get policyArrivalAndCheckinP3 =>
      'अंतर समझें: आपका स्लॉट आपका आधिकारिक समय है, जबकि लाइव कतार स्थिति और अनुमानित प्रतीक्षा काउंटर की वास्तविक गति दर्शाते हैं।';

  @override
  String get policyOnMyWayGraceTitle =>
      '\"मैं रास्ते में हूँ\" (I\'m On My Way) और ग्रेस अवधि';

  @override
  String get policyOnMyWayGraceP1 =>
      'यदि यात्रा में थोड़ी देरी हो रही है, तो टोकन वेटिंग या कॉल्ड स्थिति में होने पर आप \"I\'m On My Way\" बटन दबा सकते हैं।';

  @override
  String get policyOnMyWayGraceP2 =>
      'यह आपकी आगमन ग्रेस अवधि में एक बार के लिए 5 मिनट का अतिरिक्त समय प्रदान करता है।';

  @override
  String get policyOnMyWayGraceP3 =>
      'यह विस्तार प्रति अपॉइंटमेंट केवल एक बार उपयोग किया जा सकता है। दूसरा प्रयास सिस्टम द्वारा अस्वीकार कर दिया जाता है।';

  @override
  String get policyOnMyWayGraceP4 =>
      'इस सुविधा का उपयोग अतिरिक्त समय देता है लेकिन आपकी मूल अपॉइंटमेंट को स्थायी रूप से पुनर्निर्धारित नहीं करता।';

  @override
  String get policyServiceCompletionTitle =>
      'सेवा वितरण और नागरिक दोहरी पुष्टि';

  @override
  String get policyServiceCompletionP1 =>
      'बुलाए जाने पर निर्धारित काउंटर पर जाएं। अधिकारी आपके दस्तावेजों की भौतिक जांच करेंगे और सेवा प्रदान करेंगे।';

  @override
  String get policyServiceCompletionP2 =>
      'सेवा पूर्ण होने पर, काउंटर अधिकारी परिणाम और वास्तव में सेवा प्राप्त करने वाले व्यक्तियों की संख्या दर्ज करते हैं।';

  @override
  String get policyServiceCompletionP3 =>
      'ऑनलाइन अपॉइंटमेंट के लिए सफल सेवा पूर्णता की पुष्टि करने हेतु ऐप में दोहरी पुष्टि स्क्रीन दिखाई देती है।';

  @override
  String get policyServiceCompletionP4 =>
      'सेवा गुणवत्ता में सुधार के लिए आप 1 से 5 स्टार रेटिंग और वैकल्पिक प्रतिक्रिया सबमिट कर सकते हैं।';

  @override
  String get policyCantAttendDelayClosureTitle =>
      'रद्दीकरण, कार्यालय विलंब और केंद्र बंदी के नियम';

  @override
  String get policyCantAttendDelayClosureP1 =>
      'यदि आप उपस्थित नहीं हो सकते, तो टोकन वेटिंग या कॉल्ड स्थिति में होने पर ऐप से रद्द कर सकते हैं। कोई जुर्माना नहीं लगता।';

  @override
  String get policyCantAttendDelayClosureP2 =>
      'स्वयं-सेवा पुनर्निर्धारण वर्तमान में उपलब्ध नहीं है। नया समय चुनने के लिए सक्रिय टोकन रद्द करें और नया स्लॉट बुक करें।';

  @override
  String get policyCantAttendDelayClosureP3 =>
      'सेवा शुरू होने (Serving स्थिति) या सेवा पूरी होने के बाद रद्दीकरण की अनुमति नहीं है।';

  @override
  String get policyCantAttendDelayClosureP4 =>
      'कार्यालय विलंब: काउंटर पर होने वाला विलंब नागरिक की गलती नहीं है। ऐप रीयल-टाइम सूचना दिखाता है। अपॉइंटमेंट को गलत तरीके से नहीं हटाया जाता।';

  @override
  String get policyCantAttendDelayClosureP5 =>
      'केंद्र बंदी: यदि आपातकाल या अवकाश के कारण कार्यालय या सेवा बंद है, तो नई बुकिंग अवरुद्ध हो जाती है। नागरिक पुनः खुलने पर नई बुकिंग करें।';

  @override
  String get policyNoShowDispatchTitle => 'देर से आगमन और नो-शो (No-Show) नीति';

  @override
  String get policyNoShowDispatchP1 =>
      'यदि नागरिक ग्रेस समय समाप्त होने से पहले चेक-इन करने में विफल रहता है, तो टोकन पास-ओवर या नो-शो चिह्नित हो सकता है।';

  @override
  String get policyNoShowDispatchP2 =>
      'काउंटर अनुपस्थित नागरिक की प्रतीक्षा में खाली नहीं बैठते। निष्पक्ष नियमों के अनुसार प्रतीक्षा कर रहे वॉक-इन नागरिकों को सेवा दी जा सकती है।';

  @override
  String get policyTroubleshootingTitle =>
      'समस्या निवारण (यदि कुछ गलत हो तो क्या करें?)';

  @override
  String get policyTroubleshootingP1 =>
      'दस्तावेज भूल गए: अधूरे दस्तावेजों पर अधिकारी सेवा नहीं दे सकते। टोकन रद्द करें और सभी मूल दस्तावेज तैयार होने पर पुनः बुक करें।';

  @override
  String get policyTroubleshootingP2 =>
      'गलत सेवा बुक हो गई: ऐप से सक्रिय अपॉइंटमेंट रद्द करें और तुरंत सही सेवा का चयन करके बुक करें।';

  @override
  String get policyTroubleshootingP3 =>
      'सिस्टम या नेटवर्क समस्या: सक्रिय टोकन स्क्रीन रिफ्रेश करें या नागरिक केंद्र हेल्प डेस्क से तत्काल सहायता लें।';

  @override
  String get policyTroubleshootingP4 =>
      'सहायता हेतु आधिकारिक टोल-फ्री हेल्पलाइन: 1800-233-5500 (सुबह 8:00 से रात 8:00 बजे तक)।';

  @override
  String get policyMultipleServicesDuplicatesTitle =>
      'एकाधिक सेवाएं और डुप्लिकेट बुकिंग रोकथाम';

  @override
  String get policyMultipleServicesDuplicatesP1 =>
      'विभिन्न सेवाएं अलग-अलग काउंटरों द्वारा संचालित होती हैं। यदि कई सेवाओं की आवश्यकता है, तो प्रत्येक को अलग से बुक करना होगा।';

  @override
  String get policyMultipleServicesDuplicatesP2 =>
      'एकाधिक सेवाओं का एकीकृत फैमिली बंडल वर्तमान में सिस्टम में उपलब्ध नहीं है।';

  @override
  String get policyMultipleServicesDuplicatesP3 =>
      'डुप्लिकेट बुकिंग रोकथाम: एक मोबाइल नंबर पर एक ही सेवा के लिए एक दिन में केवल एक सक्रिय टोकन की अनुमति है। दूसरी बुकिंग अवरुद्ध हो जाती है।';

  @override
  String get policyFamilyGroupTitle => 'परिवार और समूह बुकिंग नियम';

  @override
  String get policyFamilyGroupP1 =>
      'एक नागरिक बुकिंग के समय समूह का आकार (1 से 5+ लोग) चुनकर परिवार के सदस्यों की ओर से बुक कर सकता है।';

  @override
  String get policyFamilyGroupP2 =>
      'चुना गया समूह आकार वास्तव में केंद्र आने वाले व्यक्तियों का होना चाहिए।';

  @override
  String get policyFamilyGroupP3 =>
      'सेवा पूर्ण करते समय अधिकारी वास्तव में सेवा प्राप्त करने वाले व्यक्तियों की सही संख्या दर्ज करते हैं।';

  @override
  String get policyPhysicalWalkinsTitle =>
      'वॉक-इन नागरिक (स्मार्टफोन रहित नागरिक)';

  @override
  String get policyPhysicalWalkinsP1 =>
      'जिन नागरिकों के पास स्मार्टफोन या इंटरनेट नहीं है, वे सीधे नागरिक केंद्र हेल्प डेस्क पर जा सकते हैं।';

  @override
  String get policyPhysicalWalkinsP2 =>
      'हेल्प डेस्क कर्मचारी अनुमानित समय दर्शाती मुद्रित पेपर पर्ची (जैसे P-001) के साथ भौतिक टोकन जारी करेंगे।';

  @override
  String get policyPhysicalWalkinsP3 =>
      'वॉक-इन नागरिक उसी एकीकृत कतार में शामिल होते हैं और ऑनलाइन अपॉइंटमेंट के साथ निष्पक्ष रूप से सेवा प्राप्त करते हैं।';

  @override
  String get policyPriorityAssistanceTitle =>
      'प्राथमिकता सहायता नीति (Priority Assistance)';

  @override
  String get policyPriorityAssistanceP1 =>
      'कतार की निष्पक्षता बनाए रखने के लिए ऑनलाइन बुकिंग में प्राथमिकता का स्व-चयन हटा दिया गया है।';

  @override
  String get policyPriorityAssistanceP2 =>
      'पात्र नागरिक (60+ वरिष्ठ नागरिक, गर्भवती महिलाएं और दिव्यांग) वैध प्रमाण के साथ हेल्प डेस्क या काउंटर पर भौतिक सत्यापन प्राप्त कर सकते हैं।';

  @override
  String get helpAndRulesTitle => 'सहायता और नियम';

  @override
  String get helpAndRulesSubtitle =>
      'अपॉइंटमेंट, आगमन, रद्दीकरण और सेवा से संबंधित महत्वपूर्ण जानकारी।';

  @override
  String get helpAndRulesAction => 'सहायता और नियम';

  @override
  String get helpAndPoliciesSection => 'सहायता और नीतियां';

  @override
  String get viewAppointmentRulesAction => 'अपॉइंटमेंट और रद्दीकरण नियम देखें';

  @override
  String get importantCivicNoticeTitle => 'महत्वपूर्ण सूचना';

  @override
  String get importantCivicNoticeBody =>
      'QueueLess अपॉइंटमेंट और कतार प्रबंधन में सहायता करता है। सेवा का अंतिम निर्णय, दस्तावेज स्वीकृति, पात्रता, सरकारी समय-सीमा और आधिकारिक अवकाश संबंधित प्राधिकरण के क्षेत्राधिकार में आते हैं।';

  @override
  String get categoryBookingRules => '1. अपॉइंटमेंट बुकिंग नियम';

  @override
  String get categoryArrivalService => '2. आगमन और सेवा वितरण';

  @override
  String get categoryChangesDelays => '3. समस्याएं और समाधान';

  @override
  String get categorySpecialRules => '4. विशेष श्रेणियां और प्रणाली नियम';

  @override
  String get secHowAppointmentsWorkTitle =>
      'QueueLess अपॉइंटमेंट कैसे कार्य करता है';

  @override
  String get secHowAppointmentsWorkP1 =>
      'नागरिक सेवा निर्धारित करने के लिए: अपना शहर चुनें, निकटतम नागरिक केंद्र चुनें और आवश्यक नगरपालिका सेवा चुनें।';

  @override
  String get secHowAppointmentsWorkP2 =>
      'दस्तावेज चेकलिस्ट की समीक्षा करें और पुष्टि करें कि मूल दस्तावेज तैयार हैं। फिर उपलब्ध कार्य दिवस और निश्चित समय स्लॉट चुनें।';

  @override
  String get secHowAppointmentsWorkP3 =>
      'साथ आने वाले व्यक्तियों की संख्या (1 से 5+) चुनें, बुकिंग की पुष्टि करें और आवंटित तिथि और समय विंडो के साथ टोकन पुष्टिकरण प्राप्त करें।';

  @override
  String get secHowAppointmentsWorkP4 =>
      'QueueLess अपॉइंटमेंट निश्चित समय स्लॉट का उपयोग करते हैं। आपको अपने बुक किए गए स्लॉट के अनुसार केंद्र पर पहुंचना आवश्यक है।';

  @override
  String get secAppointmentConfirmationTitle => 'अपॉइंटमेंट पुष्टिकरण विवरण';

  @override
  String get secAppointmentConfirmationP1 =>
      'बुकिंग के बाद विवरण दिखाई देगा: अपॉइंटमेंट तिथि, निश्चित समय स्लॉट, नागरिक केंद्र, सेवा प्रकार, व्यक्तियों की संख्या, टोकन कोड और शुल्क स्तर।';

  @override
  String get secAppointmentConfirmationP2 =>
      'पुष्टिकरण दर्शाता है कि अपॉइंटमेंट दर्ज हो गई है। यह गारंटी नहीं देता कि सरकारी कार्यालय में कभी परिचालन विलंब या आपातकालीन अवकाश नहीं होगा।';

  @override
  String get secRequiredDocumentsTitle => 'आवश्यक दस्तावेज चेकलिस्ट';

  @override
  String get secRequiredDocumentsP1 =>
      'प्रत्येक नगरपालिका सेवा के लिए अनिवार्य दस्तावेज निर्धारित होते हैं। अपॉइंटमेंट लेने से पहले चेकलिस्ट की सावधानीपूर्वक समीक्षा करें।';

  @override
  String get secRequiredDocumentsP2 =>
      'पुष्टिकरण चेकबॉक्स पुष्टि करता है कि आपके पास सभी मूल दस्तावेज और प्रतियां तैयार हैं। ऐप दस्तावेजों का इलेक्ट्रॉनिक सत्यापन नहीं करता।';

  @override
  String get secRequiredDocumentsP3 =>
      'अधूरे या अमान्य दस्तावेजों के साथ आने पर काउंटर अधिकारी सेवा प्रदान करने में असमर्थ होंगे।';

  @override
  String get secSlotFeesTitle => 'कस्टम और अग्रिम अपॉइंटमेंट शुल्क';

  @override
  String get secSlotFeesP1 =>
      '2 दिनों के भीतर मानक अपॉइंटमेंट स्लॉट के लिए ₹२० मानक शुल्क लागू है (Fee: ₹20)।';

  @override
  String get secSlotFeesP2 =>
      'अग्रिम कस्टम स्लॉट (3+ दिन बाद) ऐप में ₹50 शुल्क दिखाते हैं। वर्तमान में शुल्क केवल प्रदर्शन हेतु है, कोई वास्तविक राशि नहीं काटी जाती।';

  @override
  String get secSlotFeesP3 =>
      'शुल्क कभी भी अन्य नागरिकों पर प्राथमिकता नहीं खरीदता और न ही सेवा की गारंटी देता है। यह आधिकारिक बंदी या सर्वर डाउन से सुरक्षा नहीं देता।';

  @override
  String get secAdvanceDeadlinesTitle => 'अग्रिम बुकिंग और सरकारी समय-सीमा';

  @override
  String get secAdvanceDeadlinesP1 =>
      'आधिकारिक सरकारी समय-सीमा या अवकाश से पहले नागरिक प्रशासक ऑनलाइन अग्रिम बुकिंग बंद कर सकते हैं।';

  @override
  String get secAdvanceDeadlinesP2 =>
      'जब ऑनलाइन बुकिंग बंद हो, तब नागरिकों को व्यक्तिगत रूप से उपस्थित होकर भौतिक काउंटर प्रक्रिया का पालन करना होगा।';

  @override
  String get secArrivalCheckinTitle => 'आगमन और प्रवेश QR चेक-इन';

  @override
  String get secArrivalCheckinP1 =>
      'अपने निर्धारित अपॉइंटमेंट स्लॉट के अनुसार समय पर नागरिक केंद्र पहुंचें।';

  @override
  String get secArrivalCheckinP2 =>
      'भवन में प्रवेश करते समय, भौतिक उपस्थिति की पुष्टि करने के लिए ऐप द्वारा आधिकारिक प्रवेश द्वार QR स्कैन करें।';

  @override
  String get secArrivalCheckinP3 =>
      'दूरस्थ या अमान्य QR स्कैन अस्वीकार किए जाते हैं। आपके आगमन के बाद लाइव कतार स्थिति और प्रतीक्षा संख्या सक्रिय होती है।';

  @override
  String get secOnMyWayTitle => '\"मैं रास्ते में हूँ\" (+5 मिनट विस्तार)';

  @override
  String get secOnMyWayP1 =>
      'यदि यात्रा में थोड़ी देरी हो रही है, तो टोकन वेटिंग या कॉल्ड स्थिति में होने पर \"I\'m On My Way\" बटन दबाएं।';

  @override
  String get secOnMyWayP2 =>
      'यह सुविधा आपकी आगमन ग्रेस अवधि में एक बार के लिए 5 मिनट का अतिरिक्त समय प्रदान करती है।';

  @override
  String get secOnMyWayP3 =>
      'इसे बार-बार नहीं लिया जा सकता, यह मूल स्लॉट समय नहीं बदलता और देर से पहुंचने पर तत्काल सेवा की गारंटी नहीं देता।';

  @override
  String get secIfLateTitle => 'यदि मुझे देर हो जाए';

  @override
  String get secIfLateP1 =>
      'यदि देर हो रही है, तब भी जितनी जल्दी हो सके नागरिक केंद्र पहुंचने का प्रयास करें।';

  @override
  String get secIfLateP2 =>
      'यदि आप ग्रेस अवधि में नहीं पहुंचते हैं, तो काउंटर को चालू रखने के लिए अधिकारी अन्य प्रतीक्षा कर रहे नागरिक को बुला सकते हैं।';

  @override
  String get secIfLateP3 =>
      'देर होने का अर्थ यह नहीं है कि आपकी अपॉइंटमेंट अपने आप बाद के समय में स्थानांतरित हो जाएगी।';

  @override
  String get secNoShowTitle => 'नो-शो और निष्पक्ष प्रेषण';

  @override
  String get secNoShowP1 =>
      'यदि ऑनलाइन बुकिंग धारक ग्रेस अवधि में चेक-इन नहीं करता, तो काउंटर अधिकारी अगले पात्र नागरिक को बुलाते हैं।';

  @override
  String get secNoShowP2 =>
      'उपलब्ध क्षमता के दौरान प्रतीक्षा कर रहे वॉक-इन नागरिकों को सेवा दी जा सकती है ताकि सरकारी कर्मचारी खाली न बैठें।';

  @override
  String get secServiceCompletionTitle => 'सेवा पूर्णता और नागरिक दोहरी पुष्टि';

  @override
  String get secServiceCompletionP1 =>
      'काउंटर पर अधिकारी मूल दस्तावेजों की जांच करते हैं और सेवा परिणाम (सफल, आंशिक या अनुपलब्ध दस्तावेज) दर्ज करते हैं।';

  @override
  String get secServiceCompletionP2 =>
      'ऑनलाइन अपॉइंटमेंट के लिए आपके मोबाइल ऐप में दोहरी पुष्टि स्क्रीन दिखाई देती है ताकि आप सेवा प्राप्ति की पुष्टि कर सकें।';

  @override
  String get secRatingFeedbackTitle => 'रेटिंग और नागरिक प्रतिक्रिया';

  @override
  String get secRatingFeedbackP1 =>
      'सेवा पूर्ण होने की पुष्टि के बाद, आप 1 से 5 स्टार रेटिंग और वैकल्पिक प्रतिक्रिया सबमिट कर सकते हैं।';

  @override
  String get secRatingFeedbackP2 =>
      'आपकी प्रतिक्रिया सेवा गुणवत्ता सुधारने में मदद करती है। प्रतिक्रिया कतार प्राथमिकता या भविष्य की बुकिंग को प्रभावित नहीं करती।';

  @override
  String get secCancellationRulesTitle => 'रद्दीकरण के नियम';

  @override
  String get secCancellationRulesP1 =>
      'सेवा शुरू होने से पहले टोकन वेटिंग या कॉल्ड स्थिति में होने पर आप कभी भी ऐप से रद्द कर सकते हैं।';

  @override
  String get secCancellationRulesP2 =>
      'एक बार अधिकारी द्वारा सेवा शुरू करने (Serving स्थिति) या सेवा पूरी होने के बाद रद्दीकरण की अनुमति नहीं है।';

  @override
  String get secCancellationRulesP3 =>
      'QueueLess सक्रिय अपॉइंटमेंट रद्द करने के लिए कोई शुल्क या जुर्माना नहीं लेता।';

  @override
  String get secReschedulingPolicyTitle => 'पुनर्निर्धारण नीति';

  @override
  String get secReschedulingPolicyP1 =>
      'स्वचालित पुनर्निर्धारण वर्तमान में प्रणाली में उपलब्ध नहीं है।';

  @override
  String get secReschedulingPolicyP2 =>
      'यदि आप उपस्थित नहीं हो सकते, तो सक्रिय टोकन रद्द करें और अन्य तिथि या समय के लिए नया स्लॉट बुक करें।';

  @override
  String get secOfficeDelaysTitle => 'सरकारी और कार्यालय विलंब';

  @override
  String get secOfficeDelaysP1 =>
      'यदि सरकारी कार्यालय, काउंटर, नेटवर्क या बायोमेट्रिक प्रणाली के कारण विलंब होता है, तो नागरिक उत्तरदायी नहीं है।';

  @override
  String get secOfficeDelaysP2 =>
      'आपका बुक किया गया स्लॉट अपने आप नहीं बदलता। ऐप रीयल-टाइम सूचना दिखाता है। कार्यालय निर्देशों का पालन करें।';

  @override
  String get secOfficeClosuresTitle => 'नागरिक केंद्र और काउंटर बंदी';

  @override
  String get secOfficeClosuresP1 =>
      'आपातकाल, प्रशासनिक आदेश या सार्वजनिक अवकाश के कारण नागरिक केंद्र या सेवा अस्थायी रूप से बंद हो सकती है।';

  @override
  String get secOfficeClosuresP2 =>
      'बंद होने पर नई बुकिंग अवरुद्ध हो जाती है। आधिकारिक बंदी के दौरान प्रीमियम या कस्टम शुल्क सेवा की गारंटी नहीं देता।';

  @override
  String get secServerFailuresTitle => 'सर्वर और तकनीकी समस्याएं';

  @override
  String get secServerFailuresP1 =>
      'यदि किसी सेवा या काउंटर पर तकनीकी समस्या आती है, तो प्रशासक उस कतार को रोक सकते हैं जबकि अन्य जारी रहते हैं।';

  @override
  String get secServerFailuresP2 =>
      'लंबे समय तक सेवा बाधित रहने पर स्वचालित पुनर्निर्धारण उपलब्ध नहीं है। कृपया नागरिक केंद्र के निर्देशों का पालन करें।';

  @override
  String get secTroubleshootingTitle =>
      'समस्या निवारण (यदि कुछ गलत हो तो क्या करें)';

  @override
  String get secTroubleshootingP1 =>
      'अपॉइंटमेंट नहीं दिख रही: सुनिश्चित करें कि आप उसी मोबाइल नंबर से लॉग इन हैं और स्क्रीन रीफ्रेश करें।';

  @override
  String get secTroubleshootingP2 =>
      'चेक-इन या QR काम नहीं कर रहा: कैमरा अनुमति जांचें और प्रवेश द्वार पर प्रदर्शित आधिकारिक QR स्कैन करें।';

  @override
  String get secTroubleshootingP3 =>
      'आवश्यक दस्तावेज नहीं है: सक्रिय टोकन रद्द करें और सभी मूल दस्तावेज प्राप्त करने के बाद पुनः बुक करें।';

  @override
  String get secTroubleshootingP4 =>
      'कार्यालय विलंब या काउंटर बंद: लाइव ऐप कतार स्थिति देखें और केंद्र के हेल्प डेस्क से संपर्क करें।';

  @override
  String get secTroubleshootingP5 =>
      'डुप्लिकेट बुकिंग संदेश: आपके पास आज इस सेवा के लिए पहले से सक्रिय टोकन है; नया बुक करने से पहले उसे पूर्ण या रद्द करें।';

  @override
  String get secTroubleshootingP6 =>
      'नागरिक हेल्पलाइन: तत्काल प्रश्नों के लिए आधिकारिक टोल-फ्री हेल्पलाइन: 1800-233-5500 (सुबह 8:00 से रात 8:00 बजे तक)।';

  @override
  String get secFamilyGroupTitle => 'परिवार और समूह बुकिंग';

  @override
  String get secFamilyGroupP1 =>
      'एक नागरिक समूह का आकार (1 से 4 व्यक्ति) चुनकर परिवार के सदस्यों की ओर से बुकिंग कर सकता है।';

  @override
  String get secFamilyGroupP2 =>
      'सभी सदस्यों को आवश्यक दस्तावेजों के साथ उपस्थित होना होगा। अधिकारी वास्तव में सेवा प्राप्त करने वाले व्यक्तियों की संख्या दर्ज करते हैं।';

  @override
  String get secFamilyGroupP3 =>
      'एक बुकिंग कई सेवाओं का बंडल नहीं बनाती; यह केवल चुनी गई सेवा के लिए मान्य है।';

  @override
  String get secMultipleServicesTitle => 'एकाधिक सेवाओं की बुकिंग';

  @override
  String get secMultipleServicesP1 =>
      'विभिन्न नगरपालिका सेवाएं अलग-अलग विशिष्ट काउंटरों द्वारा संचालित होती हैं।';

  @override
  String get secMultipleServicesP2 =>
      'यदि आपको कई अलग-अलग सेवाओं की आवश्यकता है, तो आपको प्रत्येक सेवा के लिए अलग से बुकिंग करनी होगी।';

  @override
  String get secDuplicateBookingTitle => 'डुप्लिकेट बुकिंग रोकथाम';

  @override
  String get secDuplicateBookingP1 =>
      'QueueLess एक ही तिथि पर समान सेवा के लिए समान नागरिक/फोन द्वारा डुप्लिकेट सक्रिय बुकिंग को रोकता है।';

  @override
  String get secDuplicateBookingP2 =>
      'आप एक सेवा के लिए दो सक्रिय टोकन नहीं रख सकते। समय बदलने के लिए पहले मौजूदा बुकिंग रद्द करें।';

  @override
  String get secPhysicalWalkinsTitle => 'वॉक-इन नागरिक (हेल्प डेस्क)';

  @override
  String get secPhysicalWalkinsP1 =>
      'स्मार्टफोन या इंटरनेट रहित नागरिक केंद्र के हेल्प डेस्क पर व्यक्तिगत रूप से जा सकते हैं।';

  @override
  String get secPhysicalWalkinsP2 =>
      'हेल्प डेस्क कर्मचारी अनुमानित समय दर्शाती मुद्रित पेपर पर्ची (जैसे P-001) के साथ भौतिक टोकन जारी करेंगे।';

  @override
  String get secPhysicalWalkinsP3 =>
      'भौतिक और ऑनलाइन नागरिक एक ही कतार में शामिल होते हैं और काउंटर अधिकारियों द्वारा निष्पक्ष रूप से सेवा प्राप्त करते हैं।';

  @override
  String get secPriorityCitizensTitle => 'प्राथमिकता सहायता पात्रता';

  @override
  String get secPriorityCitizensP1 =>
      'प्राथमिकता प्रवेश वरिष्ठ नागरिकों (60+), गर्भवती महिलाओं और दिव्यांगों के लिए आरक्षित है।';

  @override
  String get secPriorityCitizensP2 =>
      'ऑनलाइन बुकिंग में प्राथमिकता का स्व-चयन उपलब्ध नहीं है। वैध प्रमाण के साथ हेल्प डेस्क या काउंटर पर भौतिक सत्यापन होता है।';

  @override
  String get secPrivacyDisplayTitle => 'गोपनीयता और लॉबी डिस्प्ले नीति';

  @override
  String get secPrivacyDisplayP1 =>
      'सार्वजनिक टीवी और काउंटर डिस्प्ले केवल टोकन कोड दर्शाते हैं (जैसे काउंटर 2 पर TAX-001)।';

  @override
  String get secPrivacyDisplayP2 =>
      'नागरिक के नाम, फोन नंबर या पहचान दस्तावेज कभी भी सार्वजनिक रूप से प्रदर्शित नहीं किए जाते। पंजीकृत फोन सुरक्षित रखें।';

  @override
  String get showVerificationCodeToOfficer =>
      'सेवा शुरू करने से पहले काउंटर अधिकारी को यह QR कोड दिखाएं या अपना 6-अंकीय सत्यापन कोड प्रदान करें।';

  @override
  String get counterVerificationSecretLabel => 'सत्यापन कोड';

  @override
  String get secCounterVerificationTitle => 'अनिवार्य काउंटर टोकन सत्यापन';

  @override
  String get secCounterVerificationP1 =>
      'सेवा शुरू करने से पहले काउंटर अधिकारी द्वारा आपके टोकन का सत्यापन आवश्यक है। केवल टोकन बुलाए जाने से सेवा शुरू नहीं हो सकती।';

  @override
  String get secCounterVerificationP2 =>
      'अपनी ऐप स्क्रीन या मुद्रित टर्न स्लिप पर प्रदर्शित 6-अंकीय सत्यापन कोड प्रदान करें या QR कोड दिखाएं। लॉबी स्क्रीन पर प्रदर्शित सार्वजनिक टोकन कोड का उपयोग सत्यापन के लिए नहीं किया जा सकता।';

  @override
  String get secCounterVerificationP3 =>
      'सत्यापन कोड एकल-उपयोग है और आपके नियत काउंटर से बंधा हुआ है। यदि पर्ची खो जाती है, तो अधिकृत अधिकारी आधिकारिक कारण के साथ लॉग किया गया प्रशासनिक ओवरराइड कर सकते हैं।';

  @override
  String get accompanyingPersonsSectionTitle =>
      'साथ आने वाले व्यक्तियों का विवरण (कुल अधिकतम 4)';

  @override
  String get sameCounterOnlyNotice =>
      'एक ही काउंटर नियम: साथ आने वाले सभी सदस्यों को इसी काउंटर की सेवा के लिए उपस्थित होना होगा। किसी अन्य काउंटर या विभाग के कार्य के लिए अलग अपॉइंटमेंट बुक करनी होगी।';

  @override
  String personIndexLabel(int number) {
    return 'साथ आने वाले व्यक्ति #$number';
  }

  @override
  String get accompanyingPersonNameHint => 'पूरा नाम (पहचान प्रमाण के अनुसार)';

  @override
  String get coAttendanceReasonLabel => 'इस काउंटर पर साथ आने का कारण';

  @override
  String get selectCoAttendanceReasonPrompt =>
      'इस काउंटर के लिए मान्य कारण चुनें';

  @override
  String get reasonJointApplicant => 'इस सेवा के लिए संयुक्त मालिक / सह-आवेदक';

  @override
  String get reasonAssistance => 'वरिष्ठ नागरिक / दिव्यांग आवेदक हेतु सहायता';

  @override
  String get reasonGuardian => 'कानूनी अभिभावक / अधिकृत प्रतिनिधि';

  @override
  String get reasonWitnessSignatory =>
      'दस्तावेज़ सत्यापन हेतु गवाह / हस्ताक्षरकर्ता';

  @override
  String get reasonFamilyVerification =>
      'संयुक्त पहचान सत्यापन हेतु परिवार का सदस्य';

  @override
  String get reasonOtherCounterWork =>
      'अन्य काउंटर/विभाग का कार्य (अलग बुकिंग आवश्यक)';

  @override
  String get invalidCounterReasonError =>
      'अनुमति नहीं है: साथ आने वाले व्यक्ति को अन्य काउंटर का कार्य है। कृपया उस काउंटर के लिए अलग अपॉइंटमेंट बुक करें।';

  @override
  String get missingAccompanyingDetailsPrompt =>
      'कृपया साथ आने वाले सभी व्यक्तियों का पूरा नाम और मान्य कारण दर्ज करें।';

  @override
  String get accompanyingPersonsSummary => 'साथ आने वाले व्यक्ति:';

  @override
  String get allottedSlotTimeLabel => 'आवंटित कतार समय';

  @override
  String get allottedTokensTitle => 'आवंटित टोकन और कतार समय';

  @override
  String get distinctTokensNotice =>
      'काउंटर कतार में प्रत्येक सदस्य को अपना अलग टोकन नंबर और निर्धारित समय आवंटित किया गया है।';

  @override
  String queueSlotsReservedCount(int count) {
    return 'आपके समूह के लिए $count कतार स्लॉट आवंटित किए जाएंगे।';
  }

  @override
  String get advanceLimitNotice =>
      'अपॉइंटमेंट अधिकतम 15 दिन पहले तक ही बुक किए जा सकते हैं';

  @override
  String get dateExceeds15DaysError =>
      'अपॉइंटमेंट की तारीख आज से 15 दिनों से अधिक नहीं हो सकती।';

  @override
  String get slotAvailable => 'उपलब्ध';

  @override
  String get slotTimePassed => 'समय बीत चुका';

  @override
  String get slotFullyBooked => 'पूर्णतः बुक';

  @override
  String get slotOfficeClosed => 'कार्यालय बंद है';

  @override
  String get slotBookingClosed => 'बुकिंग बंद है';

  @override
  String get slotInsufficientGroupSlots => 'समूह के लिए पर्याप्त स्लॉट नहीं';

  @override
  String get slotNoLongerAvailable =>
      'चयनित स्लॉट अब उपलब्ध नहीं है। कृपया दूसरा स्लॉट चुनें।';

  @override
  String get slotTimePassedError =>
      'बुक नहीं कर सकते: इस स्लॉट का समय बीत चुका है।';

  @override
  String get slotFullyBookedError =>
      'बुक नहीं कर सकते: यह स्लॉट पूरी तरह बुक हो चुका है।';

  @override
  String get slotGroupUnavailableError =>
      'आपके समूह के लिए पर्याप्त लगातार कतार स्लॉट उपलब्ध नहीं हैं।';

  @override
  String get slotOfficeClosedError =>
      'बुक नहीं कर सकते: इस स्लॉट के दौरान नागरिक केंद्र बंद है।';

  @override
  String get slotBookingClosedError =>
      'बुक नहीं कर सकते: इस सेवा के लिए ऑनलाइन बुकिंग बंद है।';

  @override
  String get slotsLoadingLabel => 'स्लॉट उपलब्धता जांची जा रही है…';

  @override
  String get noSlotsAvailableNotice =>
      'इस तारीख के लिए वर्तमान में कोई स्लॉट उपलब्ध नहीं है।';

  @override
  String get visitHistoryTitle => 'यात्रा इतिहास';

  @override
  String get visitHistorySubtitle =>
      'अपनी पिछली नागरिक यात्राएं, टोकन विवरण और सेवा परिणाम देखें।';

  @override
  String get noVisitsFound => 'कोई पिछला दौरा नहीं मिला';

  @override
  String get noVisitsFoundSubtitle =>
      'आपकी पिछली बुकिंग और काउंटर यात्रा रिकॉर्ड यहाँ दिखाई देंगे।';

  @override
  String get filterAll => 'सभी यात्राएं';

  @override
  String get filterCompleted => 'पूर्ण';

  @override
  String get filterUpcoming => 'सक्रिय / आगामी';

  @override
  String get filterOther => 'रद्द / छूटा';

  @override
  String get viewActiveTokenAction => 'सक्रिय टोकन देखें';

  @override
  String get visitDetailsTitle => 'यात्रा विवरण और प्रगति';
}
