// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appName => 'QueueLess';

  @override
  String get welcomeTitle => 'સરકારી સેવા મુલાકાત બુકિંગ';

  @override
  String get welcomeSubtitle =>
      'નિશ્ચિત સમય બુક કરો, લાઇવ વારો ટ્રેક કરો અને લાઈનમાં ઊભા રહેવાનું ટાળો.';

  @override
  String get selectLanguage => 'તમારી ભાષા પસંદ કરો';

  @override
  String get english => 'English';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get hindi => 'हिन्दी (હિન્દી)';

  @override
  String get continueButton => 'આગળ વધો';

  @override
  String get loginTitle => 'મોબાઇલ નંબરથી સાઇન ઇન કરો';

  @override
  String get loginSubtitle =>
      'ચકાસણી OTP મેળવવા માટે તમારો મોબાઇલ નંબર દાખલ કરો.';

  @override
  String get phoneNumber => 'મોબાઇલ નંબર';

  @override
  String get enterOtp => '૬ અંકનો OTP દાખલ કરો';

  @override
  String get sendOtp => 'ચકાસણી કોડ મોકલો';

  @override
  String get verifyOtp => 'ચકાસો અને આગળ વધો';

  @override
  String get browseOffices => 'નાગરિક સેવા કેન્દ્ર પસંદ કરો';

  @override
  String get browseServices => 'સરકારી સેવા પસંદ કરો';

  @override
  String get requiredDocuments => 'જરૂરી દસ્તાવેજો';

  @override
  String get confirmDocumentsPrompt =>
      'હું પુષ્ટિ કરું છું કે મારી પાસે તમામ જરૂરી અસલ દસ્તાવેજો તૈયાર છે.';

  @override
  String get checkAllDocsFirstNotice =>
      'કૃપા કરીને પહેલાં ઉપર દર્શાવેલ દરેક જરૂરી દસ્તાવેજ પસંદ કરો.';

  @override
  String docsVerifiedProgress(int checked, int total) {
    return '$total માંથી $checked પસંદ થયેલ';
  }

  @override
  String get bookSlot => 'નિશ્ચિત મુલાકાત બુક કરો';

  @override
  String get familyCount => 'સાથે આવતા લોકોની સંખ્યા';

  @override
  String get myToken => 'મારો સક્રિય ટોકન';

  @override
  String get appointmentTime => 'મુલાકાતનો સમય';

  @override
  String get estimatedTurn => 'અંદાજિત વારા સમય';

  @override
  String get nowServing => 'હવે સેવા';

  @override
  String get waitingAhead => 'આગળ રાહ જોતા લોકો';

  @override
  String get checkInQr => 'હાજરી ચેક-ઇન';

  @override
  String get scanEntranceQr => 'આગમનની પુષ્ટિ કરવા પ્રવેશ QR સ્કેન કરો';

  @override
  String get cancelAppointment => 'મુલાકાત રદ કરો';

  @override
  String get confirmCompletion => 'સેવા પૂર્ણ થયાની પુષ્ટિ કરો';

  @override
  String get leaveNowAlert => 'હમણાં નીકળો: તમારો વારો નજીક આવી રહ્યો છે!';

  @override
  String get doubleConfirmationPrompt =>
      'અધિકારીએ સેવા પૂર્ણ ચિહ્નિત કરી છે. કૃપા કરીને પુષ્ટિ કરો:';

  @override
  String get serviceCompleted => 'સેવા સફળતાપૂર્વક પૂર્ણ થઈ';

  @override
  String get officesTitle => 'નાગરિક સેવા કેન્દ્રો';

  @override
  String get servicesTitle => 'ઉપલબ્ધ સેવાઓ';

  @override
  String get selectOfficePrompt =>
      'તમારું સૌથી નજીકનું નગરપાલિકા કે વૉર્ડ કચેરી પસંદ કરો.';

  @override
  String get selectServicePrompt =>
      'તમને જે સરકારી સેવાની જરૂર હોય તે પસંદ કરો.';

  @override
  String get noOfficesFound => 'હાલમાં કોઈ કેન્દ્ર ઉપલબ્ધ નથી.';

  @override
  String get noServicesFound => 'આ કેન્દ્ર પર કોઈ સેવા ઉપલબ્ધ નથી.';

  @override
  String get documentChecklistTitle => 'જરૂરી દસ્તાવેજોની યાદી';

  @override
  String get documentChecklistSubtitle =>
      'કચેરીની મુલાકાત લેતા પહેલા નીચે જણાવેલ તમામ અસલ અને નકલો સાથે રાખવાની ખાતરી કરો:';

  @override
  String get categorySelectionTitle => 'બુકિંગ શ્રેણી';

  @override
  String get categoryNormalLabel => 'સામાન્ય નાગરિક';

  @override
  String get categoryPriorityLabel => 'પ્રાથમિકતા સેવા';

  @override
  String get categoryPriorityNotice =>
      'વરિષ્ઠ નાગરિકો (૬૦+), સગર્ભા બહેનો અને દિવ્યાંગ નાગરિકો માટે. પહોંચતી વખતે માન્ય ઓળખપત્ર જરૂરી છે.';

  @override
  String get beneficiaryNameLabel => 'લાભાર્થીનું નામ (વૈકલ્પિક)';

  @override
  String get beneficiaryNameHint => 'જે નાગરિક સેવા લઈ રહ્યા છે તેમનું નામ';

  @override
  String get bookAppointmentAction => 'નિશ્ચિત મુલાકાત બુક કરો';

  @override
  String get bookingConfirmationTitle => 'મુલાકાત સફળતાપૂર્વક નોંધાઈ ગઈ!';

  @override
  String get bookingSuccessMessage =>
      'તમારો ટોકન તૈયાર છે. સમયસર પહોંચવા વિનંતી જેથી ત્વરિત સેવા મળી શકે.';

  @override
  String get viewTokenAction => 'મારો ટોકન જુઓ';

  @override
  String get onlineAlternativeNotice =>
      'આ સેવા કચેરી આવ્યા વગર ઓનલાઇન પણ ઉપલબ્ધ છે! તમે સીધા પોર્ટલનો ઉપયોગ કરી શકો છો.';

  @override
  String get openOnlineLink => 'ઓનલાઇન પોર્ટલ ખોલો';

  @override
  String get avgServiceDuration => 'સરેરાશ સેવા સમય';

  @override
  String get currentQueueWait => 'વર્તમાન લાઇન પ્રતીક્ષા';

  @override
  String get minutesUnit => 'મિનિટ';

  @override
  String get retryAction => 'ફરી પ્રયાસ કરો';

  @override
  String get officeHoursLabel => 'કચેરી સમય';

  @override
  String get onMyWayAction => 'હું રસ્તામાં છું (+૫ મિનિટ)';

  @override
  String get onMyWaySuccess => 'વધારાની ૫ મિનિટ મંજૂર કરવામાં આવી છે!';

  @override
  String get onMyWayClaimed => 'સમય વધારો મેળવી લીધો છે';

  @override
  String get presenceVerified => 'કચેરી પર હાજરી ચકાસાયેલ છે';

  @override
  String get enterQrCodePrompt => 'પ્રવેશ QR કોડ દાખલ કરો અથવા સ્કેન કરો';

  @override
  String get confirmCancelPrompt => 'શું તમે ખરેખર આ મુલાકાત રદ કરવા માંગો છો?';

  @override
  String get cancelReasonLabel => 'રદ કરવાનું કારણ (વૈકલ્પિક)';

  @override
  String get etaRangePrefix => 'અંદાજિત વારા વિન્ડો:';

  @override
  String get yourTurnIsNext => 'તમારો વારો હવે પછીનો છે! (~૧ મિ)';

  @override
  String get appointmentSlotLabel => 'મુલાકાત સ્લોટ';

  @override
  String get nowServingAt => 'હાલમાં સેવા:';

  @override
  String get chooseDateTimeSlot => 'ઉપલબ્ધ મુલાકાત સ્લોટ પસંદ કરો';

  @override
  String get chooseAvailableSlotInstruction =>
      'નીચેના સમયપત્રકમાંથી ઉપલબ્ધ નિશ્ચિત મુલાકાત સ્લોટ પસંદ કરો.';

  @override
  String get selectedDateLabel => 'પસંદ કરેલ તારીખ';

  @override
  String get openCalendarAction => 'કેલેન્ડર ખોલો';

  @override
  String get quickSelectionTitle => 'ઝડપી પસંદગી';

  @override
  String get todayLabel => 'આજે';

  @override
  String get tomorrowLabel => 'આવતીકાલે';

  @override
  String get in2DaysLabel => '૨ દિવસમાં';

  @override
  String get in3DaysLabel => '૩ દિવસમાં';

  @override
  String get within2DaysFeeFree => '૨ દિવસમાં • ₹૨૦ ફી';

  @override
  String get customDateFee50 => 'વિશેષ તારીખ • ₹૫૦ ફી';

  @override
  String get normalSlotTitle => 'સામાન્ય સ્લોટ (૨ દિવસમાં) • ₹૨૦ સામાન્ય ફી';

  @override
  String get customSlotTitle => 'વિશેષ આગામી સ્લોટ • વધારાની ફી (₹૫૦)';

  @override
  String get statutoryDisclosure =>
      'વૈધાનિક ખુલાસો (નિયમ ૬.૩): વિશેષ સ્લોટ ફી સરકારી કચેરીની કટોકટી બંધ, જાહેર રજાઓ કે સર્વર વિલંબ સામે સુરક્ષા આપતી નથી.';

  @override
  String get standardNearTermNotice =>
      '૨ દિવસની અંદર સામાન્ય બુકિંગ માટે ₹૨૦ ફી લાગુ પડે છે.';

  @override
  String get availableTimeSlotsTitle => 'ઉપલબ્ધ સમય સ્લોટ્સ';

  @override
  String get slotsFullWarning =>
      'આ સમય માટે સ્લોટ ભરાઈ ગયા છે! કૃપા કરીને અન્ય ઉપલબ્ધ સ્લોટ અથવા અન્ય દિવસ પસંદ કરો. ૨ દિવસમાં સામાન્ય સ્લોટ માટે ₹૨૦ સામાન્ય ફી લાગુ પડે છે.';

  @override
  String get slotsFullBadge => 'સ્લોટ ભરાઈ ગયા';

  @override
  String get availableBadge => 'ઉપલબ્ધ';

  @override
  String get peopleCountPrompt => 'તમારી સાથે કેટલા લોકો આવી રહ્યા છે?';

  @override
  String get confirmAppointmentStandard =>
      'મુલાકાત પુષ્ટિ કરો • સામાન્ય ફી: ₹૨૦';

  @override
  String get confirmAppointmentHigher => 'મુલાકાત પુષ્ટિ કરો • વિશેષ ફી: ₹૫૦';

  @override
  String get applicantDetailsTitle => 'અરજદારની વિગતો';

  @override
  String get dateSummaryLabel => 'તારીખ:';

  @override
  String get slotTimeSummaryLabel => 'સ્લોટ સમય:';

  @override
  String get partySizeSummaryLabel => 'લોકોની સંખ્યા:';

  @override
  String get feeTierSummaryLabel => 'ફી શ્રેણી:';

  @override
  String get standardFreeTier => 'સામાન્ય સ્લોટ (₹૨૦)';

  @override
  String get customPaidTier => 'વિશેષ એડવાન્સ સ્લોટ (₹૫૦)';

  @override
  String get onePerson => '૧ વ્યક્તિ';

  @override
  String multiplePeople(Object count) {
    return '$count વ્યક્તિઓ';
  }

  @override
  String get signInTitle => 'ક્યૂલેસ સાઇન ઇન';

  @override
  String get enterMobileNumber => 'મોબાઇલ નંબર દાખલ કરો';

  @override
  String get invalidPhoneError => 'કૃપા કરીને માન્ય મોબાઇલ નંબર દાખલ કરો';

  @override
  String get invalidOtpError => 'કૃપા કરીને ૬-અંકનો ઓટીપી દાખલ કરો';

  @override
  String get pleaseWait => 'કૃપા કરીને રાહ જુઓ…';

  @override
  String get sendOtpAction => 'ચકાસણી કોડ મેળવો';

  @override
  String get verifyOtpAction => 'ઓટીપી ચકાસો અને આગળ વધો';

  @override
  String get otpLabel => '૬-અંકનો ઓટીપી';

  @override
  String get activeAppointmentBanner => 'સક્રિય એપોઇન્ટમેન્ટ ચાલુ છે';

  @override
  String tapToViewEta(String code) {
    return 'ટોકન: $code • લાઈવ સમય જોવા માટે ટેપ કરો';
  }

  @override
  String get priorityAllowedBadge => '⭐ અગ્રતા માન્ય';

  @override
  String get seniorCitizenCategory => 'વરિષ્ઠ નાગરિક (૬૦+ વર્ષ)';

  @override
  String get pregnantCategory => 'સગર્ભા / સ્તનપાન કરાવતી માતા';

  @override
  String get disabilityCategory => 'દિવ્યાંગ વ્યક્તિ (PwD)';

  @override
  String get medicalCategory => 'તબીબી કટોકટી / આરોગ્ય';

  @override
  String get eligibilityCategoryLabel => 'પાત્રતા શ્રેણી';

  @override
  String get signOutTooltip => 'સાઇન આઉટ';

  @override
  String get keepAppointmentAction => 'એપોઇન્ટમેન્ટ ચાલુ રાખો';

  @override
  String get yesCancelAction => 'હા, રદ કરો';

  @override
  String get cancelSuccessMessage => 'એપોઇન્ટમેન્ટ સફળતાપૂર્વક રદ કરવામાં આવી';

  @override
  String get priorityBadge => '⭐ અગ્રતા';

  @override
  String get notCheckedInStatus => 'હજી ચેક-ઇન કરેલ નથી';

  @override
  String get calculatingEta => 'ગણતરી કરી રહ્યાં છે…';

  @override
  String get noActiveAppointment => 'કોઈ સક્રિય એપોઇન્ટમેન્ટ નથી';

  @override
  String get cancelAction => 'રદ કરો';

  @override
  String get verifyArrivalAction => 'આગમન ચકાસો';

  @override
  String get qrCodeInstruction =>
      'તમારા આગમનની પુષ્ટિ કરવા માટે આ QR કોડ પ્રવેશ અધિકારી અથવા કાઉન્ટર સ્કેનરને બતાવો.';

  @override
  String get manualVerificationCodePrompt => 'ટોકન વેરિફિકેશન કોડ';

  @override
  String get qrFallbackOfficerNotice =>
      'જો QR સ્કેનરમાં કોઈ સમસ્યા આવે તો આ કોડ અધિકારી સાથે શેર કરો.';

  @override
  String get appointmentConfirmedCardTitle => 'મુલાકાત પુષ્ટિ થયેલ છે';

  @override
  String get appointmentFutureNotice =>
      'તમારી મુલાકાત આગામી તારીખ માટે પુષ્ટિ થયેલ છે. કચેરી ખુલ્યા પછી તમારી મુલાકાતના દિવસે લાઈવ કતાર સ્થિતિ સક્રિય થશે.';

  @override
  String get appointmentScheduledFor => 'નિયત તારીખ અને સમય';

  @override
  String get serviceLabel => 'સરકારી સેવા';

  @override
  String get civicCentreLabel => 'નાગરિક સેવા કેન્દ્ર';

  @override
  String get tokenLabel => 'ટોકન કોડ';

  @override
  String get partySizeLabel => 'સાથે આવતા લોકોની સંખ્યા';

  @override
  String get feeLabel => 'લાગુ પડતી ફી';

  @override
  String get feeDemoNotice => 'માત્ર ડેમો ફી • કોઈ પેમેન્ટ ગેટવે જોડાયેલ નથી';

  @override
  String get feeFreeNotice => 'સામાન્ય સરકારી મુલાકાત • ₹૨૦ ફી';

  @override
  String get liveQueueActiveNotice => 'સક્રિય કચેરી કતાર ટ્રેકિંગ';

  @override
  String get officeDelayAlert =>
      'કચેરીમાં હાલ સેવામાં વિલંબ થઈ રહ્યો છે. તમારી મુલાકાતનો સમય યથાવત છે, પરંતુ સેવામાં અપેક્ષા કરતાં વધુ સમય લાગી શકે છે.';

  @override
  String get cancelNotAllowedNotice =>
      'રદ કરવાનો નિયત સમય પૂર્ણ થઈ ગયો છે. આ મુલાકાત હવે ઓનલાઈન રદ કરી શકાતી નથી.';

  @override
  String get searchServicesPlaceholder => 'સેવાઓ શોધો';

  @override
  String get searchServicesTooltip => 'સેવાઓ શોધો';

  @override
  String get clearSearchTooltip => 'શોધ સાફ કરો';

  @override
  String centresOfferService(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count કેન્દ્રો આ સેવા આપે છે',
      one: '૧ કેન્દ્ર આ સેવા આપે છે',
    );
    return '$_temp0';
  }

  @override
  String serviceAvailableNotice(String serviceName) {
    return '→ $serviceName ઉપલબ્ધ';
  }

  @override
  String get noCentresOfferService =>
      'આ શહેરમાં કોઈ નાગરિક કેન્દ્ર આ સેવા આપતું નથી.';

  @override
  String get clearSearchAction => 'શોધ સાફ કરો';

  @override
  String get rulesAndPoliciesTitle => 'નિયમો અને નીતિઓ';

  @override
  String get rulesAndPoliciesSubtitle =>
      'QueueLess નો ઉપયોગ કરતી વખતે વિવિધ પરિસ્થિતિઓમાં શું કરવું તે માર્ગદર્શિકા';

  @override
  String get rulesAndPoliciesAction => 'નિયમો અને નીતિઓ';

  @override
  String get viewAppointmentPoliciesAction => 'મુલાકાત નીતિઓ જુઓ';

  @override
  String get policyFooterHeading => 'QueueLess મુલાકાત અને નાગરિક સેવા નીતિઓ';

  @override
  String get policyFooterVersion =>
      'સત્તાવાર નાગરિક સિસ્ટમ v1.1.0 • ગુજરાત ઇ-ગવર્નન્સ';

  @override
  String get policyTapToExpand => 'નિયમો જોવા માટે ટૅપ કરો';

  @override
  String get policyTapToCollapse => 'બંધ કરવા માટે ટૅપ કરો';

  @override
  String get categoryBooking => '૧. મુલાકાત બુકિંગ';

  @override
  String get categoryOnTheDay => '૨. મુલાકાતના દિવસે';

  @override
  String get categoryChangesProblems => '૩. ફેરફારો અને સમસ્યા નિવારણ';

  @override
  String get categorySpecialCases => '૪. ખાસ કેટેગરી અને વૉક-ઇન';

  @override
  String get policyBookingFlowTitle =>
      'મુલાકાત બુકિંગ અને જરૂરી દસ્તાવેજોની ચકાસણી';

  @override
  String get policyBookingFlowP1 =>
      'મુલાકાત શેડ્યૂલ કરવા માટે, સૌપ્રથમ તમારું શહેર, નજીકનું નાગરિક સુવિધા કેન્દ્ર અને જરૂરી મ્યુનિસિપલ સેવા પસંદ કરો.';

  @override
  String get policyBookingFlowP2 =>
      'બુકિંગ કરતાં પહેલાં દસ્તાવેજ ચેકલિસ્ટ ધ્યાનથી તપાસો. બધા અસલ દસ્તાવેજો તૈયાર હોવાની ખાતરી કર્યા પછી જ બુકિંગ બટન સક્રિય થશે.';

  @override
  String get policyBookingFlowP3 =>
      'તમારી અનુકૂળ તારીખ (આજે, આવતીકાલે અથવા આગળના કાર્યકારી દિવસો) અને ચોક્કસ સમય સ્લોટ પસંદ કરો.';

  @override
  String get policyBookingFlowP4 =>
      'બુકિંગ સાથે આવતા સભ્યોની સંખ્યા (૧ થી ૫+) પસંદ કરો. તમારી મુલાકાત પસંદ કરેલ તારીખ અને સમય વિન્ડો સાથે જોડાયેલી રહે છે.';

  @override
  String get policyConfirmationDetailsTitle => 'મુલાકાત કન્ફર્મેશન વિગતો';

  @override
  String get policyConfirmationDetailsP1 =>
      'કન્ફર્મ થયા પછી, તમારો ટોકન ડિસ્પ્લે કોડ (દા.ત. TAX-001), મુલાકાતની તારીખ, ચોક્કસ સ્લોટ સમય, કેન્દ્ર અને સભ્યોની સંખ્યા નોંધવામાં આવશે.';

  @override
  String get policyConfirmationDetailsP2 =>
      'તમારી મુલાકાત હોમ સ્ક્રીન અને લાઈવ ટોકન સ્ક્રીન પર દેખાય છે, જ્યાં આજ માટેનો લાઈવ કતાર સ્ટેટસ અને વેઇટિંગ કાઉન્ટ દર્શાવાય છે.';

  @override
  String get policyConfirmationDetailsP3 =>
      'કેન્દ્રની મુલાકાત વખતે બધા જરૂરી અસલ દસ્તાવેજો, નકલો અને રજિસ્ટર્ડ મોબાઈલ સાથે રાખવાનું ભૂલશો નહીં.';

  @override
  String get policySlotFeesTitle => 'ફિક્સ અપોઇન્ટમેન્ટ સ્લોટ્સ અને ફી નિયમો';

  @override
  String get policySlotFeesP1 =>
      'QueueLess મુલાકાતો ફિક્સ સ્લોટ્સ છે. અન્ય નાગરિક ગેરહાજર હોવાને કારણે તમારો સમય આપમેળે બદલાતો નથી.';

  @override
  String get policySlotFeesP2 =>
      '૨ દિવસની અંદરની સામાન્ય મુલાકાતો માટે ₹૨૦ ફી લાગુ પડે છે (Fee: ₹20).';

  @override
  String get policySlotFeesP3 =>
      'આગામી કસ્ટમ સ્લોટ્સ (૩+ દિવસ પછી) એપમાં ₹૫૦ સ્લોટ ફી દર્શાવે છે. હાલમાં સિસ્ટમમાં ફી માત્ર ડેમો/સિસ્ટમ-સિમ્યુલેટેડ છે અને કોઈ વાસ્તવિક ચુકવણી કપાતી નથી.';

  @override
  String get policySlotFeesP4 =>
      'કાયદાકીય જાહેરાત: સ્લોટ બુકિંગ અણધારી સરકારી કટોકટી, જાહેર રજાઓ અથવા સર્વર વિક્ષેપો સામે રક્ષણ આપતું નથી.';

  @override
  String get policyArrivalAndCheckinTitle => 'આગમન અને પ્રવેશ હાજરી ચેક-ઇન';

  @override
  String get policyArrivalAndCheckinP1 =>
      'નાગરિકોએ નિર્ધારિત સમય સ્લોટ પર અથવા તે પહેલાં નાગરિક કેન્દ્ર પર શારીરિક રીતે હાજર થવું જરૂરી છે.';

  @override
  String get policyArrivalAndCheckinP2 =>
      'હાજરી ચકાસવા માટે એપ વડે પ્રવેશદ્વાર પરનો સત્તાવાર QR કોડ સ્કેન કરો. દૂરથી અથવા ખોટું ચેક-ઇન સખત રીતે અટકાવવામાં આવે છે.';

  @override
  String get policyArrivalAndCheckinP3 =>
      'તફાવત સમજો: તમારો સ્લોટ તમારો સત્તાવાર સમય છે, જ્યારે લાઈવ કતાર સ્થિતિ અને અંદાજિત સમય કાઉન્ટરની ગતિ દર્શાવે છે.';

  @override
  String get policyOnMyWayGraceTitle =>
      '\"હું રસ્તામાં છું\" (I\'m On My Way) અને ગ્રેસ પિરિયડ';

  @override
  String get policyOnMyWayGraceP1 =>
      'જો મુસાફરીમાં મોડું થાય, તો ટોકન વેઇટિંગ અથવા કૉલ સ્ટેટસમાં હોય ત્યારે \"I\'m On My Way\" બટન દબાવી શકો છો.';

  @override
  String get policyOnMyWayGraceP2 =>
      'આ સુવિધા તમારા આગમન ગ્રેસ સમયમાં એક વખત માટે ૫ મિનિટનો વધારાનો સમય આપે છે.';

  @override
  String get policyOnMyWayGraceP3 =>
      'આ એક્સ્ટેંશન મુલાકાત દીઠ માત્ર એક જ વાર વાપરી શકાય છે. બીજી વખતનો પ્રયાસ સિસ્ટમ નકારી કાઢશે.';

  @override
  String get policyOnMyWayGraceP4 =>
      'આ સુવિધા વાપરવાથી વધારાનો સમય મળે છે, પરંતુ મુલાકાતનો મૂળ સ્લોટ કાયમ માટે બદલાતો નથી.';

  @override
  String get policyServiceCompletionTitle => 'સેવા વિતરણ અને નાગરિક ડબલ-પુષ્ટિ';

  @override
  String get policyServiceCompletionP1 =>
      'કૉલ થાય ત્યારે નિયુક્ત કાઉન્ટર પર જાઓ. અધિકારી તમારા દસ્તાવેજોની ભૌતિક ચકાસણી કરશે અને સેવા પૂરી પાડશે.';

  @override
  String get policyServiceCompletionP2 =>
      'સેવા સમાપ્ત થયા પછી, અધિકારી પરિણામ અને ખરેખર સેવા લીધેલ વ્યક્તિઓની સંખ્યા નોંધશે.';

  @override
  String get policyServiceCompletionP3 =>
      'ઓનલાઈન મુલાકાતો માટે સફળ સેવા પૂર્ણ થયાની પુષ્ટિ કરવા એપમાં ડબલ-કન્ફર્મેશન સ્ક્રીન દેખાશે.';

  @override
  String get policyServiceCompletionP4 =>
      'સેવા ગુણવત્તા સુધારવા માટે તમે ૧ થી ૫ સ્ટાર રેટિંગ અને વૈકલ્પિક પ્રતિસાદ સબમિટ કરી શકો છો.';

  @override
  String get policyCantAttendDelayClosureTitle =>
      'રદ્દીકરણ, ઓફિસ વિલંબ અને કેન્દ્ર બંધ થવાના નિયમો';

  @override
  String get policyCantAttendDelayClosureP1 =>
      'જો તમે હાજર ન રહી શકો, તો ટોકન વેઇટિંગ અથવા કૉલ સ્ટેટસમાં હોય ત્યારે એપમાંથી રદ કરી શકો છો. કોઈ દંડ લાગતો નથી.';

  @override
  String get policyCantAttendDelayClosureP2 =>
      'સ્વતંત્ર રિશેડ્યુલિંગ હાલમાં ઉપલબ્ધ નથી. નવો સમય પસંદ કરવા સક્રિય ટોકન રદ કરીને નવો સ્લોટ બુક કરો.';

  @override
  String get policyCantAttendDelayClosureP3 =>
      'કાઉન્ટર પર સેવા શરૂ થયા પછી (Serving) અથવા સેવા પૂર્ણ થયા પછી ટોકન રદ કરી શકાતું નથી.';

  @override
  String get policyCantAttendDelayClosureP4 =>
      'સરકારી વિલંબ: કાઉન્ટર પરનો વિલંબ નાગરિકનો વાંક નથી. એપ લાઈવ વિલંબ સૂચના દર્શાવે છે. અપોઇન્ટમેન્ટ આપમેળે ખસેડવામાં આવતી નથી.';

  @override
  String get policyCantAttendDelayClosureP5 =>
      'કેન્દ્ર બંધ રહેવું: કટોકટી કે રજાના કારણે ઓફિસ કે સેવા બંધ હોય તો નવા બુકિંગ અટકે છે. નાગરિકોએ ફરી ખુલ્યા પછી બુકિંગ કરવું.';

  @override
  String get policyNoShowDispatchTitle => 'મોડું આગમન અને નો-શો (No-Show) નીતિ';

  @override
  String get policyNoShowDispatchP1 =>
      'જો નાગરિક ગ્રેસ સમય સમાપ્ત થાય તે પહેલાં હાજર ન થાય, તો ટોકન પાસ-ઓવર અથવા નો-શો ચિહ્નિત થઈ શકે છે.';

  @override
  String get policyNoShowDispatchP2 =>
      'ગેરહાજર નાગરિક માટે કાઉન્ટર ખાલી બેસી રહેતું નથી. યોગ્ય ડિસ્પેચ નિયમો મુજબ પ્રતીક્ષા કરતા વૉક-ઇન નાગરિકોને સેવા આપી શકાય છે.';

  @override
  String get policyTroubleshootingTitle =>
      'મુશ્કેલી નિવારણ (કંઈક ખોટું થાય ત્યારે શું કરવું?)';

  @override
  String get policyTroubleshootingP1 =>
      'દસ્તાવેજો ભૂલી ગયા: અધૂરા દસ્તાવેજે અધિકારી કામ કરી શકતા નથી. ટોકન રદ કરી બધા અસલ દસ્તાવેજો તૈયાર થાય ત્યારે ફરી બુક કરો.';

  @override
  String get policyTroubleshootingP2 =>
      'ખોટી સેવા બુક થઈ ગઈ: એપમાંથી સક્રિય મુલાકાત રદ કરી ડિરેક્ટરીમાંથી સાચી સેવા તરત જ પસંદ કરો.';

  @override
  String get policyTroubleshootingP3 =>
      'સિસ્ટમ અથવા નેટવર્ક સમસ્યા: સક્રિય ટોકન સ્ક્રીન રિફ્રેશ કરો અથવા નાગરિક કેન્દ્ર હેલ્પ ડેસ્કનો તાત્કાલિક સંપર્ક કરો.';

  @override
  String get policyTroubleshootingP4 =>
      'સહાયતા માટે સત્તાવાર ટોલ-ફ્રી હેલ્પલાઇન: 1800-233-5500 (સવારે ૮:૦૦ થી રાત્રે ૮:૦૦).';

  @override
  String get policyMultipleServicesDuplicatesTitle =>
      'બહુવિધ સેવાઓ અને ડુપ્લિકેટ બુકિંગ નિવારણ';

  @override
  String get policyMultipleServicesDuplicatesP1 =>
      'વિવિધ સેવાઓ અલગ-અલગ કાઉન્ટર દ્વારા સંચાલિત થાય છે. જો એક કરતાં વધુ સેવાની જરૂર હોય, તો દરેકનું અલગ બુકિંગ કરવું પડશે.';

  @override
  String get policyMultipleServicesDuplicatesP2 =>
      'બહુવિધ સેવાઓનું સંયુક્ત ફેમિલી બંડલ હાલમાં સિસ્ટમમાં ઉપલબ્ધ નથી.';

  @override
  String get policyMultipleServicesDuplicatesP3 =>
      'ડુપ્લિકેટ બુકિંગ નિવારણ: એક મોબાઈલ નંબર દીઠ એક જ સેવા માટે દિવસમાં માત્ર એક સક્રિય ટોકન માન્ય છે. બીજું સક્રિય બુકિંગ બ્લૉક થાય છે.';

  @override
  String get policyFamilyGroupTitle => 'પરિવાર અને જૂથ બુકિંગ નિયમો';

  @override
  String get policyFamilyGroupP1 =>
      'એક નાગરિક બુકિંગ વખતે જૂથનું કદ (૧ થી ૫+ લોકો) પસંદ કરીને પરિવારના સભ્યો માટે બુક કરી શકે છે.';

  @override
  String get policyFamilyGroupP2 =>
      'પસંદ કરેલ સંખ્યા કેન્દ્રમાં ખરેખર સાથે આવનાર વ્યક્તિઓની હોવી જોઈએ.';

  @override
  String get policyFamilyGroupP3 =>
      'સેવા પૂર્ણ કરતી વખતે અધિકારી ખરેખર સેવા મેળવેલ વ્યક્તિઓની સંખ્યા નોંધે છે.';

  @override
  String get policyPhysicalWalkinsTitle =>
      'વૉક-ઇન નાગરિકો (સ્માર્ટફોન વિનાના નાગરિકો)';

  @override
  String get policyPhysicalWalkinsP1 =>
      'જે નાગરિકો પાસે સ્માર્ટફોન કે ઇન્ટરનેટ નથી, તેઓ કેન્દ્રના હેલ્પ ડેસ્ક પર રૂબરૂ જઈ શકે છે.';

  @override
  String get policyPhysicalWalkinsP2 =>
      'હેલ્પ ડેસ્ક સ્ટાફ અંદાજિત સમય દર્શાવતી પ્રિન્ટેડ પેપર સ્લિપ (દા.ત. P-001) સાથે ભૌતિક ટોકન આપશે.';

  @override
  String get policyPhysicalWalkinsP3 =>
      'વૉક-ઇન નાગરિકો સમાન કતારમાં જોડાય છે અને ઓનલાઈન નાગરિકો સાથે ન્યાયી રીતે સેવા મેળવે છે.';

  @override
  String get policyPriorityAssistanceTitle =>
      'પ્રાથમિકતા સહાય નીતિ (Priority Assistance)';

  @override
  String get policyPriorityAssistanceP1 =>
      'કતારની ન્યાયીતા જાળવવા સામાન્ય ઓનલાઈન બુકિંગમાં પ્રાથમિકતાની જાતે પસંદગી બંધ કરવામાં આવી છે.';

  @override
  String get policyPriorityAssistanceP2 =>
      'લાયક નાગરિકો (૬૦+ વરિષ્ઠ નાગરિકો, સગર્ભા મહિલાઓ અને દિવ્યાંગો) માન્ય પુરાવા સાથે હેલ્પ ડેસ્ક કે કાઉન્ટર પર રૂબરૂ ચકાસણી મેળવી શકે છે.';

  @override
  String get helpAndRulesTitle => 'મદદ અને નિયમો';

  @override
  String get helpAndRulesSubtitle =>
      'મુલાકાત, આગમન, રદ્દીકરણ અને સેવા સંબંધિત મહત્વપૂર્ણ માહિતી.';

  @override
  String get helpAndRulesAction => 'મદદ અને નિયમો';

  @override
  String get helpAndPoliciesSection => 'મદદ અને નીતિઓ';

  @override
  String get viewAppointmentRulesAction => 'મુલાકાત અને રદ્દીકરણના નિયમો જુઓ';

  @override
  String get importantCivicNoticeTitle => 'મહત્વપૂર્ણ સૂચના';

  @override
  String get importantCivicNoticeBody =>
      'QueueLess અપોઇન્ટમેન્ટ અને કતાર વ્યવસ્થાપનમાં મદદ કરે છે. સેવાનો આખરી નિર્ણય, દસ્તાવેજ સ્વીકૃતિ, પાત્રતા, સરકારી મુદતો અને સત્તાવાર રજાઓ સંબંધિત સત્તામંડળના અધિકારક્ષેત્ર હેઠળ રહે છે.';

  @override
  String get categoryBookingRules => '૧. મુલાકાત બુકિંગના નિયમો';

  @override
  String get categoryArrivalService => '૨. આગમન અને સેવા વિતરણ';

  @override
  String get categoryChangesDelays => '૩. સમસ્યાઓ અને ઉપાયો';

  @override
  String get categorySpecialRules => '૪. ખાસ કેટેગરી અને સિસ્ટમ નિયમો';

  @override
  String get secHowAppointmentsWorkTitle =>
      'QueueLess અપોઇન્ટમેન્ટ કેવી રીતે કાર્ય કરે છે';

  @override
  String get secHowAppointmentsWorkP1 =>
      'નાગરિક સેવા શેડ્યૂલ કરવા: તમારું શહેર પસંદ કરો, નજીકનું નાગરિક કેન્દ્ર પસંદ કરો અને જરૂરી મ્યુનિસિપલ સેવા પસંદ કરો.';

  @override
  String get secHowAppointmentsWorkP2 =>
      'દસ્તાવેજ ચેકલિસ્ટ તપાસો અને અસલ દસ્તાવેજો તૈયાર હોવાની પુષ્ટિ કરો. પછી ઉપલબ્ધ કાર્યકારી તારીખ અને ચોક્કસ સમય સ્લોટ પસંદ કરો.';

  @override
  String get secHowAppointmentsWorkP3 =>
      'સાથે આવનાર વ્યક્તિઓની સંખ્યા (૧ થી ૫+) પસંદ કરો, બુકિંગ કન્ફર્મ કરો અને ફાળવેલ તારીખ અને સમય વિન્ડો સાથે ટોકન કન્ફર્મેશન મેળવો.';

  @override
  String get secHowAppointmentsWorkP4 =>
      'QueueLess મુલાકાતો ફિક્સ સમય સ્લોટનો ઉપયોગ કરે છે. તમારે તમારા બુક કરેલા સ્લોટ મુજબ કેન્દ્ર પર પહોંચવું જરૂરી છે.';

  @override
  String get secAppointmentConfirmationTitle => 'મુલાકાત કન્ફર્મેશન વિગતો';

  @override
  String get secAppointmentConfirmationP1 =>
      'બુકિંગ પછી વિગતો દેખાશે: મુલાકાત તારીખ, ફિક્સ સમય સ્લોટ, નાગરિક કેન્દ્ર, સેવાનો પ્રકાર, વ્યક્તિઓની સંખ્યા, ટોકન કોડ અને ફી સ્તર.';

  @override
  String get secAppointmentConfirmationP2 =>
      'કન્ફર્મેશન દર્શાવે છે કે મુલાકાત નોંધાઈ ગઈ છે. તે સરકારી કચેરીમાં અણધાર્યા વિલંબ કે સત્તાવાર રજા નહિ આવે તેની ખાતરી આપતું નથી.';

  @override
  String get secRequiredDocumentsTitle => 'જરૂરી દસ્તાવેજ ચેકલિસ્ટ';

  @override
  String get secRequiredDocumentsP1 =>
      'દરેક મ્યુનિસિપલ સેવા માટે ચોક્કસ દસ્તાવેજો જરૂરી હોય છે. શેડ્યૂલ કરતાં પહેલાં ચેકલિસ્ટ ધ્યાનથી તપાસો.';

  @override
  String get secRequiredDocumentsP2 =>
      'કન્ફર્મેશન ચેકબોક્સ ખાતરી કરે છે કે તમારી પાસે બધા અસલ દસ્તાવેજો અને નકલો તૈયાર છે. એપ દસ્તાવેજોની ઇલેક્ટ્રોનિક ચકાસણી કરતી નથી.';

  @override
  String get secRequiredDocumentsP3 =>
      'અધૂરા કે અમાન્ય દસ્તાવેજો સાથે આવવાથી કાઉન્ટર અધિકારી સેવા આપી શકશે નહીં.';

  @override
  String get secSlotFeesTitle => 'કસ્ટમ અને ભાવિ મુલાકાત ફી';

  @override
  String get secSlotFeesP1 =>
      '૨ દિવસની અંદરના સામાન્ય મુલાકાત સ્લોટ્સ માટે ₹૨૦ સામાન્ય ફી લાગુ પડે છે (Fee: ₹20).';

  @override
  String get secSlotFeesP2 =>
      'આગામી કસ્ટમ સ્લોટ્સ (૩+ દિવસ પછી) એપમાં ₹૫૦ ફી દર્શાવે છે. હાલમાં સિસ્ટમમાં ફી માત્ર ડેમો છે, કોઈ વાસ્તવિક પૈસા કપાતા નથી.';

  @override
  String get secSlotFeesP3 =>
      'ફી ક્યારેય અન્ય નાગરિકો પર પ્રાથમિકતા ખરીદતી નથી કે સેવાની ખાતરી આપતી નથી. તે સત્તાવાર રજા કે સર્વર ડાઉન સામે રક્ષણ આપતી નથી.';

  @override
  String get secAdvanceDeadlinesTitle => 'એડવાન્સ બુકિંગ અને સરકારી મુદતો';

  @override
  String get secAdvanceDeadlinesP1 =>
      'સત્તાવાર સરકારી ડેડલાઇન કે રજાઓ પહેલાં નાગરિક વહીવટકર્તા ઓનલાઇન એડવાન્સ બુકિંગ બંધ કરી શકે છે.';

  @override
  String get secAdvanceDeadlinesP2 =>
      'જ્યારે ઓનલાઇન બુકિંગ બંધ હોય, ત્યારે નાગરિકોએ રૂબરૂ જઈને ભૌતિક કાઉન્ટર પ્રક્રિયાનું પાલન કરવું પડશે.';

  @override
  String get secArrivalCheckinTitle => 'આગમન અને પ્રવેશ QR ચેક-ઇન';

  @override
  String get secArrivalCheckinP1 =>
      'તમારા શેડ્યૂલ કરેલા મુલાકાત સ્લોટ મુજબ સમયસર નાગરિક કેન્દ્ર પર પહોંચો.';

  @override
  String get secArrivalCheckinP2 =>
      'ઇમારતમાં પ્રવેશતી વખતે, ભૌતિક હાજરીની પુષ્ટિ કરવા માટે એપ દ્વારા સત્તાવાર પ્રવેશદ્વાર QR સ્કેન કરો.';

  @override
  String get secArrivalCheckinP3 =>
      'દૂરથી કે અમાન્ય QR સ્કેન નકારવામાં આવે છે. તમે પહોંચ્યા પછી લાઈવ કતાર સ્થિતિ અને આગળ પ્રતીક્ષા કરતી સંખ્યા સક્રિય થાય છે.';

  @override
  String get secOnMyWayTitle => '\"હું રસ્તામાં છું\" (+૫ મિનિટ એક્સ્ટેંશન)';

  @override
  String get secOnMyWayP1 =>
      'જો મુસાફરીમાં મોડું થાય, તો ટોકન વેઇટિંગ અથવા કૉલ સ્ટેટસમાં હોય ત્યારે \"I\'m On My Way\" બટન દબાવો.';

  @override
  String get secOnMyWayP2 =>
      'આ સુવિધા તમારા આગમન ગ્રેસ સમયમાં એક વખત માટે ૫ મિનિટનો વધારાનો સમય આપે છે.';

  @override
  String get secOnMyWayP3 =>
      'તે વારંવાર માગી શકાતી નથી, મુલાકાતનો મૂળ સમય બદલતી નથી અને મોડા પહોંચવા પર તાત્કાલિક સેવાની ખાતરી આપતી નથી.';

  @override
  String get secIfLateTitle => 'જો હું મોડો પડું તો';

  @override
  String get secIfLateP1 =>
      'જો મોડું થઈ રહ્યું હોય, તો પણ શક્ય તેટલી ઝડપે નાગરિક કેન્દ્ર પર પહોંચવાનો પ્રયાસ કરો.';

  @override
  String get secIfLateP2 =>
      'જો તમે ગ્રેસ સમયમાં ન પહોંચો, તો કાઉન્ટર ચાલુ રાખવા માટે અધિકારી અન્ય પ્રતીક્ષા કરતા નાગરિકને બોલાવી શકે છે.';

  @override
  String get secIfLateP3 =>
      'મોડું થવાનો અર્થ એ નથી કે તમારી મુલાકાત આપમેળે આગળના સમયમાં ખસેડાઈ જશે.';

  @override
  String get secNoShowTitle => 'નો-શો અને ન્યાયી ડિસ્પેચ';

  @override
  String get secNoShowP1 =>
      'જો ઓનલાઇન બુકિંગ ધારક ગ્રેસ સમયમાં ચેક-ઇન ન કરે, તો કાઉન્ટર અધિકારી આગામી લાયક નાગરિકને બોલાવે છે.';

  @override
  String get secNoShowP2 =>
      'ખાલી ક્ષમતા દરમિયાન પ્રતીક્ષા કરતા વૉક-ઇન નાગરિકોને સેવા આપી શકાય છે જેથી સરકારી સ્ટાફ નવરો ન બેસે.';

  @override
  String get secServiceCompletionTitle => 'સેવા પૂર્ણતા અને નાગરિક ડબલ-પુષ્ટિ';

  @override
  String get secServiceCompletionP1 =>
      'કાઉન્ટર પર અધિકારી અસલ દસ્તાવેજો તપાસે છે અને સેવાનું પરિણામ (સફળ, આંશિક અથવા ખૂટતા દસ્તાવેજ) નોંધે છે.';

  @override
  String get secServiceCompletionP2 =>
      'ઓનલાઇન મુલાકાતો માટે તમારી મોબાઇલ એપમાં ડબલ-કન્ફર્મેશન સ્ક્રીન દેખાશે જેથી તમે સેવા પૂર્ણ થયાની પુષ્ટિ કરી શકો.';

  @override
  String get secRatingFeedbackTitle => 'રેટિંગ અને નાગરિક પ્રતિસાદ';

  @override
  String get secRatingFeedbackP1 =>
      'સેવા પૂર્ણ થયાની પુષ્ટિ કર્યા પછી, તમે ૧ થી ૫ સ્ટાર રેટિંગ અને વૈકલ્પિક પ્રતિસાદ સબમિટ કરી શકો છો.';

  @override
  String get secRatingFeedbackP2 =>
      'તમારો પ્રતિસાદ સેવાની ગુણવત્તા સુધારવામાં મદદ કરે છે. પ્રતિસાદ કતાર પ્રાથમિકતા કે ભવિષ્યના બુકિંગને અસર કરતો નથી.';

  @override
  String get secCancellationRulesTitle => 'રદ્દીકરણના નિયમો';

  @override
  String get secCancellationRulesP1 =>
      'સેવા શરૂ થાય તે પહેલાં ટોકન વેઇટિંગ અથવા કૉલ સ્ટેટસમાં હોય ત્યારે તમે ગમે ત્યારે એપમાંથી રદ કરી શકો છો.';

  @override
  String get secCancellationRulesP2 =>
      'એકવાર અધિકારી સેવા શરૂ કરે (Serving સ્થિતિ) અથવા સેવા પૂર્ણ થયા પછી રદ્દીકરણની મંજૂરી નથી.';

  @override
  String get secCancellationRulesP3 =>
      'QueueLess સક્રિય મુલાકાત રદ કરવા માટે કોઈ ફી કે દંડ વસૂલતું નથી.';

  @override
  String get secReschedulingPolicyTitle => 'રીશેડ્યુલિંગ નીતિ';

  @override
  String get secReschedulingPolicyP1 =>
      'સ્વતંત્ર આપમેળે રીશેડ્યુલિંગ હાલમાં સિસ્ટમમાં ઉપલબ્ધ નથી.';

  @override
  String get secReschedulingPolicyP2 =>
      'જો તમે હાજર ન રહી શકો, તો સક્રિય ટોકન રદ કરો અને અન્ય તારીખ કે સમય માટે નવો સ્લોટ બુક કરો.';

  @override
  String get secOfficeDelaysTitle => 'સરકારી અને કચેરી વિલંબ';

  @override
  String get secOfficeDelaysP1 =>
      'જો સરકારી કચેરી, કાઉન્ટર, નેટવર્ક કે બાયોમેટ્રિક સિસ્ટમના કારણે વિલંબ થાય, તો નાગરિક જવાબદાર ગણાતા નથી.';

  @override
  String get secOfficeDelaysP2 =>
      'તમારો બુક કરેલો સ્લોટ આપમેળે બદલાતો નથી. એપ લાઈવ વિલંબ સૂચના દર્શાવે છે. કચેરીની સૂચનાઓનું પાલન કરો.';

  @override
  String get secOfficeClosuresTitle => 'નાગરિક કેન્દ્ર અને કાઉન્ટર બંધ રહેવું';

  @override
  String get secOfficeClosuresP1 =>
      'કટોકટી, વહીવટી આદેશ કે જાહેર રજાના કારણે નાગરિક કેન્દ્ર કે સેવા અસ્થાયી રૂપે બંધ થઈ શકે છે.';

  @override
  String get secOfficeClosuresP2 =>
      'બંધ હોય ત્યારે નવા બુકિંગ અટકે છે. સત્તાવાર બંધ દરમિયાન પ્રીમિયમ કે કસ્ટમ ફી સેવાની ખાતરી આપતી નથી.';

  @override
  String get secServerFailuresTitle => 'સર્વર અને ટેકનિકલ સમસ્યાઓ';

  @override
  String get secServerFailuresP1 =>
      'જો કોઈ સેવા કે કાઉન્ટર પર ટેકનિકલ સમસ્યા સર્જાય, તો વહીવટકર્તા તે કતાર અટકાવી શકે છે જ્યારે અન્ય ચાલુ રહે છે.';

  @override
  String get secServerFailuresP2 =>
      'લાંબા સમયના આઉટેજ માટે આપમેળે રીશેડ્યુલિંગ ઉપલબ્ધ નથી. કૃપા કરીને નાગરિક કેન્દ્રની સૂચનાઓનું પાલન કરો.';

  @override
  String get secTroubleshootingTitle =>
      'મુશ્કેલી નિવારણ (કંઈક ખોટું થાય ત્યારે શું કરવું)';

  @override
  String get secTroubleshootingP1 =>
      'અપોઇન્ટમેન્ટ દેખાતી નથી: બુકિંગ વખતે વાપરેલા મોબાઇલ નંબરથી લોગ ઇન છો તેની ખાતરી કરો અને રિફ્રેશ કરો.';

  @override
  String get secTroubleshootingP2 =>
      'ચેક-ઇન કે QR કામ કરતું નથી: કેમેરા પરવાનગી તપાસો અને પ્રવેશદ્વાર પર દર્શાવેલ સત્તાવાર QR સ્કેન કરો.';

  @override
  String get secTroubleshootingP3 =>
      'જરૂરી દસ્તાવેજ ખૂટે છે: સક્રિય ટોકન રદ કરો અને બધા અસલ દસ્તાવેજો મેળવ્યા પછી ફરીથી બુક કરો.';

  @override
  String get secTroubleshootingP4 =>
      'કચેરી વિલંબ કે કાઉન્ટર બંધ: લાઈવ એપ કતાર સ્થિતિ તપાસો અને કેન્દ્રના હેલ્પ ડેસ્કનો સંપર્ક કરો.';

  @override
  String get secTroubleshootingP5 =>
      'ડુપ્લિકેટ બુકિંગ સંદેશ: તમારી પાસે આજે આ સેવા માટે સક્રિય ટોકન પહેલેથી છે; નવું બુક કરતાં પહેલાં તે પૂર્ણ કે રદ કરો.';

  @override
  String get secTroubleshootingP6 =>
      'નાગરિક હેલ્પલાઇન: તાત્કાલિક પ્રશ્નો માટે સત્તાવાર ટોલ-ફ્રી હેલ્પલાઇન: 1800-233-5500 (સવારે ૮:૦૦ થી રાત્રે ૮:૦૦).';

  @override
  String get secFamilyGroupTitle => 'પરિવાર અને જૂથ બુકિંગ';

  @override
  String get secFamilyGroupP1 =>
      'એક નાગરિક જૂથનું કદ (1 થી 4 વ્યક્તિઓ) પસંદ કરીને કુટુંબના સભ્યો વતી બુકિંગ કરી શકે છે.';

  @override
  String get secFamilyGroupP2 =>
      'બધા સભ્યોએ જરૂરી દસ્તાવેજો સાથે હાજર રહેવું પડશે. અધિકારી ખરેખર સેવા મેળવેલ વ્યક્તિઓની સંખ્યા નોંધે છે.';

  @override
  String get secFamilyGroupP3 =>
      'એક બુકિંગ બહુવિધ સેવાનું બંડલ બનાવતું નથી; તે માત્ર પસંદ કરેલી સેવા માટે જ માન્ય છે.';

  @override
  String get secMultipleServicesTitle => 'બહુવિધ સેવાઓનું બુકિંગ';

  @override
  String get secMultipleServicesP1 =>
      'વિવિધ મ્યુનિસિપલ સેવાઓ અલગ-અલગ વિશિષ્ટ કાઉન્ટર દ્વારા સંચાલિત થાય છે.';

  @override
  String get secMultipleServicesP2 =>
      'જો તમારે એક કરતાં વધુ અલગ સેવાઓની જરૂર હોય, તો તમારે દરેક સેવા માટે અલગ બુકિંગ કરવું પડશે.';

  @override
  String get secDuplicateBookingTitle => 'ડુપ્લિકેટ બુકિંગ નિવારણ';

  @override
  String get secDuplicateBookingP1 =>
      'QueueLess એક જ તારીખે સમાન સેવા માટે સમાન નાગરિક/ફોન દીઠ ડુપ્લિકેટ સક્રિય બુકિંગ સખત રીતે અટકાવે છે.';

  @override
  String get secDuplicateBookingP2 =>
      'તમે એક સેવા માટે બે સક્રિય ટોકન રાખી શકતા નથી. સમય બદલવા માટે પહેલાં હાલનું બુકિંગ રદ કરો.';

  @override
  String get secPhysicalWalkinsTitle => 'વૉક-ઇન નાગરિકો (હેલ્પ ડેસ્ક)';

  @override
  String get secPhysicalWalkinsP1 =>
      'સ્માર્ટફોન કે ઇન્ટરનેટ ન ધરાવતા નાગરિકો કેન્દ્રના હેલ્પ ડેસ્ક પર રૂબરૂ મુલાકાત લઈ શકે છે.';

  @override
  String get secPhysicalWalkinsP2 =>
      'હેલ્પ ડેસ્ક સ્ટાફ અંદાજિત સમય દર્શાવતી પ્રિન્ટેડ પેપર સ્લિપ (દા.ત. P-001) સાથે ભૌતિક ટોકન આપે છે.';

  @override
  String get secPhysicalWalkinsP3 =>
      'ભૌતિક અને ઓનલાઇન નાગરિકો સમાન કતારમાં જોડાય છે અને કાઉન્ટર અધિકારીઓ દ્વારા ન્યાયી રીતે સેવા મેળવે છે.';

  @override
  String get secPriorityCitizensTitle => 'પ્રાથમિકતા સહાય પાત્રતા';

  @override
  String get secPriorityCitizensP1 =>
      'પ્રાથમિકતા પ્રવેશ વરિષ્ઠ નાગરિકો (૬૦+), સગર્ભા મહિલાઓ અને દિવ્યાંગો માટે અનામત છે.';

  @override
  String get secPriorityCitizensP2 =>
      'ઓનલાઇન બુકિંગમાં પ્રાથમિકતાની જાતે પસંદગી કરી શકાતી નથી. માન્ય પુરાવા સાથે હેલ્પ ડેસ્ક કે કાઉન્ટર પર રૂબરૂ ચકાસણી થાય છે.';

  @override
  String get secPrivacyDisplayTitle => 'ગોપનીયતા અને લોબી ડિસ્પ્લે નીતિ';

  @override
  String get secPrivacyDisplayP1 =>
      'જાહેર ટીવી અને કાઉન્ટર ડિસ્પ્લે માત્ર ટોકન કોડ દર્શાવે છે (દા.ત. કાઉન્ટર ૨ પર TAX-001).';

  @override
  String get secPrivacyDisplayP2 =>
      'નાગરિકના નામ, ફોન નંબર કે ઓળખ દસ્તાવેજો ક્યારેય જાહેરમાં દર્શાવવામાં આવતા નથી. રજિસ્ટર્ડ ફોન સુરક્ષિત રાખો.';

  @override
  String get showVerificationCodeToOfficer =>
      'સેવા શરૂ કરતા પહેલાં કાઉન્ટર અધિકારીને આ QR કોડ બતાવો અથવા તમારો 6-અંકનો ચકાસણી કોડ આપો.';

  @override
  String get counterVerificationSecretLabel => 'ચકાસણી કોડ';

  @override
  String get secCounterVerificationTitle => 'કાઉન્ટર ટોકન ચકાસણી (ફરજિયાત)';

  @override
  String get secCounterVerificationP1 =>
      'સેવા શરૂ કરતા પહેલાં કાઉન્ટર અધિકારીએ તમારા ટોકનની ચકાસણી કરવી ફરજિયાત છે. માત્ર ટોકન બોલાવવાથી સેવા શરૂ થઈ શકતી નથી.';

  @override
  String get secCounterVerificationP2 =>
      'તમારા એપ સ્ક્રીન અથવા પ્રિન્ટેડ ટર્ન સ્લિપ પર દર્શાવેલ 6-અંકનો ચકાસણી કોડ આપો અથવા QR કોડ બતાવો. લોબી સ્ક્રીન પર દર્શાવતો જાહેર ટોકન કોડ ચકાસણી માટે વાપરી શકાતો નથી.';

  @override
  String get secCounterVerificationP3 =>
      'ચકાસણી રહસ્ય માત્ર એક જ વાર વાપરી શકાય છે અને તમારા ફાળવેલ કાઉન્ટર સાથે બંધાયેલ છે. જો તમે સ્લિપ ગુમાવી હોય તો અધિકૃત અધિકારી સત્તાવાર કારણ સાથે ઓવરરાઇડ કરી શકે છે.';

  @override
  String get accompanyingPersonsSectionTitle =>
      'સાથે આવનાર વ્યક્તિઓની વિગતો (કુલ મહત્તમ 4)';

  @override
  String get sameCounterOnlyNotice =>
      'એક જ કાઉન્ટર નિયમ: સાથે આવનાર તમામ સભ્યોએ આ જ કાઉન્ટરની સેવા માટે આવવું જરૂરી છે. અન્ય કાઉન્ટર અથવા વિભાગના કામ માટે અલગ એપોઇન્ટમેન્ટ બુક કરવી પડશે.';

  @override
  String personIndexLabel(int number) {
    return 'સાથે આવનાર વ્યક્તિ #$number';
  }

  @override
  String get accompanyingPersonNameHint => 'પૂરું નામ (ઓળખ પુરાવા મુજબ)';

  @override
  String get coAttendanceReasonLabel => 'આ કાઉન્ટર પર સાથે આવવાનું કારણ';

  @override
  String get selectCoAttendanceReasonPrompt =>
      'આ કાઉન્ટર માટે માન્ય કારણ પસંદ કરો';

  @override
  String get reasonJointApplicant => 'આ સેવા માટે સંયુક્ત માલિક / સહ-અરજદાર';

  @override
  String get reasonAssistance => 'વરિષ્ઠ નાગરિક / દિવ્યાંગ અરજદાર માટે સહાયતા';

  @override
  String get reasonGuardian => 'કાનૂની વાલી / અધિકૃત પ્રતિનિધિ';

  @override
  String get reasonWitnessSignatory =>
      'દસ્તાવેજ ચકાસણી માટે સાક્ષી / સહી કરનાર';

  @override
  String get reasonFamilyVerification =>
      'સંયુક્ત ઓળખ ચકાસણી માટે કુટુંબના સભ્ય';

  @override
  String get reasonOtherCounterWork =>
      'અન્ય કાઉન્ટર/વિભાગનું કામ (અલગ બુકિંગ જરૂરી)';

  @override
  String get invalidCounterReasonError =>
      'મંજૂરી નથી: સાથે આવનાર વ્યક્તિને અન્ય કાઉન્ટરનું કામ છે. કૃપા કરીને તે કાઉન્ટર માટે અલગ એપોઇન્ટમેન્ટ બુક કરો.';

  @override
  String get missingAccompanyingDetailsPrompt =>
      'કૃપા કરીને સાથે આવનાર તમામ વ્યક્તિઓનું પૂરું નામ અને માન્ય કારણ ભરો.';

  @override
  String get accompanyingPersonsSummary => 'સાથે આવનાર વ્યક્તિઓ:';

  @override
  String get allottedSlotTimeLabel => 'ફાળવેલ કતાર સમય';

  @override
  String get allottedTokensTitle => 'ફાળવેલ ટોકન અને કતાર સમય';

  @override
  String get distinctTokensNotice =>
      'કાઉન્ટર કતારમાં દરેક સભ્યને પોતાનો અલગ ટોકન નંબર અને નિર્ધારિત સમય ફાળવવામાં આવેલ છે.';

  @override
  String queueSlotsReservedCount(int count) {
    return 'તમારા જૂથ માટે $count કતાર સ્લોટ ફાળવવામાં આવશે.';
  }

  @override
  String get advanceLimitNotice =>
      'મુલાકાત વધુમાં વધુ 15 દિવસ અગાઉ સુધી જ બુક કરી શકાય છે';

  @override
  String get dateExceeds15DaysError =>
      'મુલાકાતની તારીખ આજથી 15 દિવસથી વધુ હોઈ શકતી નથી.';

  @override
  String get slotAvailable => 'ઉપલબ્ધ';

  @override
  String get slotTimePassed => 'સમય વીતી ગયો';

  @override
  String get slotFullyBooked => 'સંપૂર્ણ બુક';

  @override
  String get slotOfficeClosed => 'કચેરી બંધ છે';

  @override
  String get slotBookingClosed => 'બુકિંગ બંધ છે';

  @override
  String get slotInsufficientGroupSlots => 'જૂથ માટે પૂરતા સ્લોટ નથી';

  @override
  String get slotNoLongerAvailable =>
      'પસંદ કરેલ સ્લોટ હવે ઉપલબ્ધ નથી. કૃપા કરીને અન્ય સ્લોટ પસંદ કરો.';

  @override
  String get slotTimePassedError =>
      'બુક કરી શકાતું નથી: આ સ્લોટનો સમય વીતી ગયો છે.';

  @override
  String get slotFullyBookedError =>
      'બુક કરી શકાતું નથી: આ સ્લોટ સંપૂર્ણ બુક થઈ ગયો છે.';

  @override
  String get slotGroupUnavailableError =>
      'તમારા જૂથ માટે પૂરતા ક્રમિક કતાર સ્લોટ ઉપલબ્ધ નથી.';

  @override
  String get slotOfficeClosedError =>
      'બુક કરી શકાતું નથી: આ સ્લોટ દરમિયાન નાગરિક કેન્દ્ર બંધ છે.';

  @override
  String get slotBookingClosedError =>
      'બુક કરી શકાતું નથી: આ સેવા માટે ઓનલાઇન બુકિંગ બંધ છે.';

  @override
  String get slotsLoadingLabel => 'સ્લોટ ઉપલબ્ધતા તપાસી રહ્યા છીએ…';

  @override
  String get noSlotsAvailableNotice =>
      'આ તારીખ માટે હાલમાં કોઈ સ્લોટ ઉપલબ્ધ નથી.';
}
