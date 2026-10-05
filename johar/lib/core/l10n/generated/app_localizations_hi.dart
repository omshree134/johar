// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'जोहार';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get continueButton => 'आगे बढ़ें';

  @override
  String get registerTitle => 'कर्मचारी की जानकारी';

  @override
  String get registerHint => 'आपके सुपरवाइज़र यह आपके साथ भर सकते हैं।';

  @override
  String get fieldName => 'पूरा नाम';

  @override
  String get fieldWorkerId => 'कर्मचारी आईडी (कंपनी से)';

  @override
  String get fieldEmployer => 'कंपनी या खदान का नाम';

  @override
  String get fieldRequired => 'कृपया यह भरें';

  @override
  String get sectorLabel => 'आप कहाँ काम करते हैं?';

  @override
  String get sectorCoal => 'कोयला खदान';

  @override
  String get sectorSteel => 'स्टील प्लांट';

  @override
  String get sectorMica => 'अभ्रक इकाई';

  @override
  String get saveAndStart => 'सेव करें और ट्रेनिंग शुरू करें';

  @override
  String homeGreeting(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get homeSubtitle =>
      'हर ट्रेनिंग पूरी करें और अपना सुरक्षा प्रमाणपत्र पाएँ।';

  @override
  String get changeLanguage => 'भाषा बदलें';

  @override
  String get navLearn => 'ट्रेनिंग';

  @override
  String get navCertificates => 'प्रमाणपत्र';

  @override
  String get navVerify => 'प्रमाणपत्र जाँचें';

  @override
  String syncPending(int count) {
    return '$count परिणाम इंटरनेट का इंतज़ार कर रहे हैं';
  }

  @override
  String get syncDone => 'सभी परिणाम सेव हो गए';

  @override
  String get syncWorking => 'परिणाम सेव हो रहे हैं…';

  @override
  String get moduleFire => 'आग और विस्फोट';

  @override
  String get moduleGas => 'गैस रिसाव और बंद जगह';

  @override
  String get moduleMachinery => 'मशीनरी सुरक्षा';

  @override
  String get moduleElectrical => 'बिजली सुरक्षा';

  @override
  String get moduleFirstAid => 'प्राथमिक चिकित्सा और निकासी';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get passedStatus => 'पास';

  @override
  String get notStarted => 'शुरू नहीं किया';

  @override
  String lessonStep(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get next => 'आगे';

  @override
  String get back => 'पीछे';

  @override
  String get startPractice => 'कैमरे से अभ्यास करें';

  @override
  String get arModeWorld => 'इस फ़ोन पर 3D AR उपलब्ध है';

  @override
  String get arModeCamera => 'कैमरा अभ्यास मोड';

  @override
  String get cameraPermissionNeeded =>
      'अपने असली आसपास में अभ्यास के लिए कैमरे की अनुमति चाहिए।';

  @override
  String get allowCamera => 'कैमरा चालू करें';

  @override
  String get noCameraNote => 'कैमरा नहीं मिला। नमूना कार्यस्थल पर अभ्यास करें।';

  @override
  String timeLeft(int seconds) {
    return '$seconds सेकंड बाकी';
  }

  @override
  String get taskCorrect => 'सही';

  @override
  String get taskWrong => 'यह सुरक्षित नहीं है। फिर कोशिश करें।';

  @override
  String get taskTimeUp => 'समय खत्म';

  @override
  String get checkSelection => 'मेरा चुनाव जाँचें';

  @override
  String get nextTask => 'अगला काम';

  @override
  String get startQuiz => 'टेस्ट शुरू करें';

  @override
  String questionOf(int current, int total) {
    return 'प्रश्न $current / $total';
  }

  @override
  String get checkAnswer => 'उत्तर जाँचें';

  @override
  String get seeResult => 'मेरा परिणाम देखें';

  @override
  String get resultPassed => 'आप पास हो गए';

  @override
  String get resultFailed => 'अभी पास नहीं हुए';

  @override
  String yourScore(int score) {
    return 'अंक: $score%';
  }

  @override
  String get criticalMissed =>
      'आपसे जान बचाने वाला एक प्रश्न छूट गया। पास होने के लिए इनका सही उत्तर ज़रूरी है।';

  @override
  String get certificateOnTheWay =>
      'फ़ोन इंटरनेट से जुड़ते ही आपका प्रमाणपत्र जारी होगा।';

  @override
  String get tryAgain => 'फिर से करें';

  @override
  String get backHome => 'ट्रेनिंग पर वापस';

  @override
  String get certificatesEmpty =>
      'अभी कोई प्रमाणपत्र नहीं है। ट्रेनिंग पास करके प्रमाणपत्र पाएँ।';

  @override
  String get certPending => 'जारी होने के लिए इंटरनेट का इंतज़ार';

  @override
  String certValidUntil(String date) {
    return '$date तक मान्य';
  }

  @override
  String get certShowHint => 'यह कोड अपने सुपरवाइज़र या निरीक्षक को दिखाएँ।';

  @override
  String get verifyScanHint => 'कैमरे को प्रमाणपत्र के कोड की ओर करें';

  @override
  String get verifyValid => 'असली प्रमाणपत्र';

  @override
  String get verifyExpired => 'प्रमाणपत्र की अवधि खत्म हो गई है';

  @override
  String get verifyInvalid => 'यह असली प्रमाणपत्र नहीं है';

  @override
  String get verifyRevoked => 'प्रमाणपत्र रद्द कर दिया गया है';

  @override
  String get verifyNotConfigured => 'इस ऐप में जाँच की कुंजी सेट नहीं है';

  @override
  String get verifyOnlineOk => 'ऑनलाइन भी जाँचा गया: सक्रिय';

  @override
  String get verifyOnlineUnknown => 'सिर्फ़ ऑफ़लाइन जाँचा गया';

  @override
  String get scanAnother => 'दूसरा स्कैन करें';

  @override
  String get workerIdLabel => 'कर्मचारी आईडी';

  @override
  String get certIdLabel => 'प्रमाणपत्र आईडी';

  @override
  String get arIntroTitle => 'अपने असली आसपास में अभ्यास करें';

  @override
  String get arIntroStand =>
      'किसी खुली जगह पर स्थिर खड़े हों और उसी जगह घूमकर चारों ओर देखें। अभ्यास करते समय चलें नहीं।';

  @override
  String get arTrackingSensor => 'चारों ओर देखने के लिए फ़ोन घुमाएँ';

  @override
  String get arTrackingTouch =>
      'चारों ओर देखने के लिए स्क्रीन पर उँगली खिसकाएँ';

  @override
  String get arStart => 'अभ्यास शुरू करें';

  @override
  String get arRecenter => 'सामने की ओर करें';

  @override
  String get arSelect => 'चुनें';

  @override
  String arFound(int found, int total) {
    return '$total में से $found मिले';
  }

  @override
  String get arPullPin => 'पिन खींचें';

  @override
  String get arHoldToSpray => 'छिड़कने के लिए दबाए रखें';

  @override
  String get arPullPinFirst => 'पहले पिन खींचें';

  @override
  String get arAimLow => 'नीचे, आग की जड़ पर निशाना लगाएँ';

  @override
  String get arSweep => 'दाएँ-बाएँ घुमाएँ';

  @override
  String get arFireLabel => 'आग';

  @override
  String get arExtinguisherLabel => 'अग्निशामक';

  @override
  String get arFireOut => 'आग बुझ गई';

  @override
  String get arExtinguisherEmpty =>
      'अग्निशामक खाली हो गया। जगह छोड़ें और अलार्म बजाएँ।';

  @override
  String get arFireTooBig => 'आग बहुत बड़ी है। तुरंत निकलें और अलार्म बजाएँ।';

  @override
  String get arHoldToMeasure => 'मापने के लिए दबाए रखें';

  @override
  String get arPointAtLevel => 'मापने के लिए किसी स्तर की ओर करें';

  @override
  String get arDecideSafe => 'अंदर जाना सुरक्षित है';

  @override
  String get arDecideUnsafe => 'सुरक्षित नहीं: हवा चलाएँ और फिर जाँचें';

  @override
  String arDetectorTitle(String level) {
    return 'गैस डिटेक्टर: $level';
  }

  @override
  String homeJohar(String name) {
    return 'जोहार, $name!';
  }

  @override
  String get progressTitle => 'आपकी सुरक्षा ट्रेनिंग';

  @override
  String progressCount(int done, int total) {
    return '$total में से $done ट्रेनिंग पास';
  }

  @override
  String get sectionTrainings => 'ट्रेनिंग';

  @override
  String get workersTitle => 'इस फ़ोन पर कर्मचारी';

  @override
  String get addWorker => 'कर्मचारी जोड़ें';

  @override
  String certExpiresSoon(String module, int days) {
    return '$module प्रमाणपत्र $days दिनों में समाप्त होगा';
  }

  @override
  String certExpiredBanner(String module) {
    return '$module प्रमाणपत्र समाप्त हो गया है';
  }

  @override
  String get retakeTraining => 'ट्रेनिंग फिर से करें';

  @override
  String get refresherBannerTitle => '7 दिन की याददाश्त जाँच';

  @override
  String refresherBannerBody(String module) {
    return '$module: 5 छोटे प्रश्न, देखें आपको क्या याद है।';
  }

  @override
  String get refresherStart => 'जाँच शुरू करें';

  @override
  String get refresherResultTitle => 'याददाश्त जाँच पूरी';

  @override
  String refresherRemembered(int score) {
    return 'आपको $score% याद रहा';
  }

  @override
  String refresherBefore(int score) {
    return 'ट्रेनिंग के तुरंत बाद: $score%';
  }

  @override
  String get refresherGood => 'बहुत अच्छा याद रखा। ऐसे ही रखें!';

  @override
  String get refresherRetake =>
      'कुछ बातें भूल गए। ताज़ा करने के लिए ट्रेनिंग फिर से करें।';

  @override
  String get arLookCloser => 'पास से देखें';

  @override
  String arStepOf(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get arReportHazard => 'खतरा बताएँ';

  @override
  String get arGoThisWay => 'इस रास्ते जाएँ';

  @override
  String get arRemove => 'हटाएँ';

  @override
  String get arDoNext => 'अब यह करें';

  @override
  String get arClose => 'बंद करें';

  @override
  String get arSelectedPill => 'चुना गया';

  @override
  String get arWrongOrder => 'अभी नहीं। सोचें पहले क्या होना चाहिए।';

  @override
  String get narrationListen => 'सुनें';

  @override
  String get narrationStop => 'रोकें';
}
