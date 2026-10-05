// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Johar';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get continueButton => 'Continue';

  @override
  String get registerTitle => 'Worker details';

  @override
  String get registerHint => 'Your supervisor can fill this in with you.';

  @override
  String get fieldName => 'Full name';

  @override
  String get fieldWorkerId => 'Worker ID (from employer)';

  @override
  String get fieldEmployer => 'Company or mine name';

  @override
  String get fieldRequired => 'Please fill this in';

  @override
  String get sectorLabel => 'Where do you work?';

  @override
  String get sectorCoal => 'Coal mine';

  @override
  String get sectorSteel => 'Steel plant';

  @override
  String get sectorMica => 'Mica unit';

  @override
  String get saveAndStart => 'Save and start training';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeSubtitle =>
      'Finish each training to get your safety certificate.';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get navLearn => 'Training';

  @override
  String get navCertificates => 'Certificates';

  @override
  String get navVerify => 'Check certificate';

  @override
  String syncPending(int count) {
    return '$count results waiting for internet';
  }

  @override
  String get syncDone => 'All results saved';

  @override
  String get syncWorking => 'Saving results…';

  @override
  String get moduleFire => 'Fire and explosion';

  @override
  String get moduleGas => 'Gas leak and confined space';

  @override
  String get moduleMachinery => 'Machinery safety';

  @override
  String get moduleElectrical => 'Electrical safety';

  @override
  String get moduleFirstAid => 'First aid and evacuation';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get passedStatus => 'Passed';

  @override
  String get notStarted => 'Not started';

  @override
  String lessonStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get startPractice => 'Practise with camera';

  @override
  String get arModeWorld => '3D AR available on this phone';

  @override
  String get arModeCamera => 'Camera practice mode';

  @override
  String get cameraPermissionNeeded =>
      'Camera access is needed to practise in your real surroundings.';

  @override
  String get allowCamera => 'Allow camera';

  @override
  String get noCameraNote =>
      'No camera found. Practising on a sample workplace.';

  @override
  String timeLeft(int seconds) {
    return '${seconds}s left';
  }

  @override
  String get taskCorrect => 'Correct';

  @override
  String get taskWrong => 'Not safe. Try again.';

  @override
  String get taskTimeUp => 'Time is up';

  @override
  String get checkSelection => 'Check my choice';

  @override
  String get nextTask => 'Next task';

  @override
  String get startQuiz => 'Start the test';

  @override
  String questionOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get checkAnswer => 'Check answer';

  @override
  String get seeResult => 'See my result';

  @override
  String get resultPassed => 'You passed';

  @override
  String get resultFailed => 'Not passed yet';

  @override
  String yourScore(int score) {
    return 'Score: $score%';
  }

  @override
  String get criticalMissed =>
      'You missed a life-safety question. These must be answered correctly to pass.';

  @override
  String get certificateOnTheWay =>
      'Your certificate will be issued when the phone connects to the internet.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get backHome => 'Back to training';

  @override
  String get certificatesEmpty =>
      'No certificates yet. Pass a training to get one.';

  @override
  String get certPending => 'Waiting for internet to issue';

  @override
  String certValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get certShowHint => 'Show this code to your supervisor or inspector.';

  @override
  String get verifyScanHint => 'Point the camera at a certificate code';

  @override
  String get verifyValid => 'Genuine certificate';

  @override
  String get verifyExpired => 'Certificate has expired';

  @override
  String get verifyInvalid => 'Not a genuine certificate';

  @override
  String get verifyRevoked => 'Certificate was cancelled';

  @override
  String get verifyNotConfigured =>
      'Verification key not set up in this app build';

  @override
  String get verifyOnlineOk => 'Also checked online: active';

  @override
  String get verifyOnlineUnknown => 'Checked offline only';

  @override
  String get scanAnother => 'Scan another';

  @override
  String get workerIdLabel => 'Worker ID';

  @override
  String get certIdLabel => 'Certificate ID';

  @override
  String get arIntroTitle => 'Practise in your real surroundings';

  @override
  String get arIntroStand =>
      'Stand still in a clear space and turn on the spot to look around. Do not walk while practising.';

  @override
  String get arTrackingSensor => 'Move your phone to look around';

  @override
  String get arTrackingTouch => 'Drag the screen to look around';

  @override
  String get arStart => 'Start practice';

  @override
  String get arRecenter => 'Face forward';

  @override
  String get arSelect => 'Select';

  @override
  String arFound(int found, int total) {
    return 'Found $found of $total';
  }

  @override
  String get arPullPin => 'Pull the pin';

  @override
  String get arHoldToSpray => 'Hold to spray';

  @override
  String get arPullPinFirst => 'Pull the pin first';

  @override
  String get arAimLow => 'Aim lower, at the base of the fire';

  @override
  String get arSweep => 'Sweep side to side';

  @override
  String get arFireLabel => 'Fire';

  @override
  String get arExtinguisherLabel => 'Extinguisher';

  @override
  String get arFireOut => 'Fire is out';

  @override
  String get arExtinguisherEmpty =>
      'The extinguisher is empty. Leave the area and raise the alarm.';

  @override
  String get arFireTooBig =>
      'The fire is too big. Leave now and raise the alarm.';

  @override
  String get arHoldToMeasure => 'Hold to measure';

  @override
  String get arPointAtLevel => 'Point at a level to measure it';

  @override
  String get arDecideSafe => 'Safe to enter';

  @override
  String get arDecideUnsafe => 'Not safe: ventilate and test again';

  @override
  String arDetectorTitle(String level) {
    return 'Gas detector: $level';
  }

  @override
  String homeJohar(String name) {
    return 'Johar, $name!';
  }

  @override
  String get progressTitle => 'Your safety training';

  @override
  String progressCount(int done, int total) {
    return '$done of $total trainings passed';
  }

  @override
  String get sectionTrainings => 'Trainings';

  @override
  String get workersTitle => 'Workers on this phone';

  @override
  String get addWorker => 'Add a worker';

  @override
  String certExpiresSoon(String module, int days) {
    return '$module certificate expires in $days days';
  }

  @override
  String certExpiredBanner(String module) {
    return '$module certificate has expired';
  }

  @override
  String get retakeTraining => 'Retake training';

  @override
  String get refresherBannerTitle => '7-day memory check';

  @override
  String refresherBannerBody(String module) {
    return '$module: 5 quick questions to see what you remember.';
  }

  @override
  String get refresherStart => 'Start check';

  @override
  String get refresherResultTitle => 'Memory check done';

  @override
  String refresherRemembered(int score) {
    return 'You remembered $score%';
  }

  @override
  String refresherBefore(int score) {
    return 'Right after training: $score%';
  }

  @override
  String get refresherGood => 'Well remembered. Keep it up!';

  @override
  String get refresherRetake =>
      'Some things were forgotten. Take the training again to refresh them.';

  @override
  String get arLookCloser => 'Look closer';

  @override
  String arStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get arReportHazard => 'Report hazard';

  @override
  String get arGoThisWay => 'Go this way';

  @override
  String get arRemove => 'Remove';

  @override
  String get arDoNext => 'Do this next';

  @override
  String get arClose => 'Close';

  @override
  String get arSelectedPill => 'Selected';

  @override
  String get arWrongOrder => 'Not yet. Think about what must happen first.';

  @override
  String get narrationListen => 'Listen';

  @override
  String get narrationStop => 'Stop';
}
