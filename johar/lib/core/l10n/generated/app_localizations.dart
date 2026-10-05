import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_sat.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('hi'),
    Locale('sat'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Johar'**
  String get appTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker details'**
  String get registerTitle;

  /// No description provided for @registerHint.
  ///
  /// In en, this message translates to:
  /// **'Your supervisor can fill this in with you.'**
  String get registerHint;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldName;

  /// No description provided for @fieldWorkerId.
  ///
  /// In en, this message translates to:
  /// **'Worker ID (from employer)'**
  String get fieldWorkerId;

  /// No description provided for @fieldEmployer.
  ///
  /// In en, this message translates to:
  /// **'Company or mine name'**
  String get fieldEmployer;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill this in'**
  String get fieldRequired;

  /// No description provided for @sectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Where do you work?'**
  String get sectorLabel;

  /// No description provided for @sectorCoal.
  ///
  /// In en, this message translates to:
  /// **'Coal mine'**
  String get sectorCoal;

  /// No description provided for @sectorSteel.
  ///
  /// In en, this message translates to:
  /// **'Steel plant'**
  String get sectorSteel;

  /// No description provided for @sectorMica.
  ///
  /// In en, this message translates to:
  /// **'Mica unit'**
  String get sectorMica;

  /// No description provided for @saveAndStart.
  ///
  /// In en, this message translates to:
  /// **'Save and start training'**
  String get saveAndStart;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finish each training to get your safety certificate.'**
  String get homeSubtitle;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get navLearn;

  /// No description provided for @navCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get navCertificates;

  /// No description provided for @navVerify.
  ///
  /// In en, this message translates to:
  /// **'Check certificate'**
  String get navVerify;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} results waiting for internet'**
  String syncPending(int count);

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'All results saved'**
  String get syncDone;

  /// No description provided for @syncWorking.
  ///
  /// In en, this message translates to:
  /// **'Saving results…'**
  String get syncWorking;

  /// No description provided for @moduleFire.
  ///
  /// In en, this message translates to:
  /// **'Fire and explosion'**
  String get moduleFire;

  /// No description provided for @moduleGas.
  ///
  /// In en, this message translates to:
  /// **'Gas leak and confined space'**
  String get moduleGas;

  /// No description provided for @moduleMachinery.
  ///
  /// In en, this message translates to:
  /// **'Machinery safety'**
  String get moduleMachinery;

  /// No description provided for @moduleElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical safety'**
  String get moduleElectrical;

  /// No description provided for @moduleFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid and evacuation'**
  String get moduleFirstAid;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @passedStatus.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passedStatus;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// No description provided for @lessonStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String lessonStep(int current, int total);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Practise with camera'**
  String get startPractice;

  /// No description provided for @arModeWorld.
  ///
  /// In en, this message translates to:
  /// **'3D AR available on this phone'**
  String get arModeWorld;

  /// No description provided for @arModeCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera practice mode'**
  String get arModeCamera;

  /// No description provided for @cameraPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to practise in your real surroundings.'**
  String get cameraPermissionNeeded;

  /// No description provided for @allowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get allowCamera;

  /// No description provided for @noCameraNote.
  ///
  /// In en, this message translates to:
  /// **'No camera found. Practising on a sample workplace.'**
  String get noCameraNote;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s left'**
  String timeLeft(int seconds);

  /// No description provided for @taskCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get taskCorrect;

  /// No description provided for @taskWrong.
  ///
  /// In en, this message translates to:
  /// **'Not safe. Try again.'**
  String get taskWrong;

  /// No description provided for @taskTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time is up'**
  String get taskTimeUp;

  /// No description provided for @checkSelection.
  ///
  /// In en, this message translates to:
  /// **'Check my choice'**
  String get checkSelection;

  /// No description provided for @nextTask.
  ///
  /// In en, this message translates to:
  /// **'Next task'**
  String get nextTask;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start the test'**
  String get startQuiz;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionOf(int current, int total);

  /// No description provided for @checkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check answer'**
  String get checkAnswer;

  /// No description provided for @seeResult.
  ///
  /// In en, this message translates to:
  /// **'See my result'**
  String get seeResult;

  /// No description provided for @resultPassed.
  ///
  /// In en, this message translates to:
  /// **'You passed'**
  String get resultPassed;

  /// No description provided for @resultFailed.
  ///
  /// In en, this message translates to:
  /// **'Not passed yet'**
  String get resultFailed;

  /// No description provided for @yourScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}%'**
  String yourScore(int score);

  /// No description provided for @criticalMissed.
  ///
  /// In en, this message translates to:
  /// **'You missed a life-safety question. These must be answered correctly to pass.'**
  String get criticalMissed;

  /// No description provided for @certificateOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Your certificate will be issued when the phone connects to the internet.'**
  String get certificateOnTheWay;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to training'**
  String get backHome;

  /// No description provided for @certificatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet. Pass a training to get one.'**
  String get certificatesEmpty;

  /// No description provided for @certPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for internet to issue'**
  String get certPending;

  /// No description provided for @certValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String certValidUntil(String date);

  /// No description provided for @certShowHint.
  ///
  /// In en, this message translates to:
  /// **'Show this code to your supervisor or inspector.'**
  String get certShowHint;

  /// No description provided for @verifyScanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a certificate code'**
  String get verifyScanHint;

  /// No description provided for @verifyValid.
  ///
  /// In en, this message translates to:
  /// **'Genuine certificate'**
  String get verifyValid;

  /// No description provided for @verifyExpired.
  ///
  /// In en, this message translates to:
  /// **'Certificate has expired'**
  String get verifyExpired;

  /// No description provided for @verifyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a genuine certificate'**
  String get verifyInvalid;

  /// No description provided for @verifyRevoked.
  ///
  /// In en, this message translates to:
  /// **'Certificate was cancelled'**
  String get verifyRevoked;

  /// No description provided for @verifyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Verification key not set up in this app build'**
  String get verifyNotConfigured;

  /// No description provided for @verifyOnlineOk.
  ///
  /// In en, this message translates to:
  /// **'Also checked online: active'**
  String get verifyOnlineOk;

  /// No description provided for @verifyOnlineUnknown.
  ///
  /// In en, this message translates to:
  /// **'Checked offline only'**
  String get verifyOnlineUnknown;

  /// No description provided for @scanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan another'**
  String get scanAnother;

  /// No description provided for @workerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker ID'**
  String get workerIdLabel;

  /// No description provided for @certIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate ID'**
  String get certIdLabel;

  /// No description provided for @arIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Practise in your real surroundings'**
  String get arIntroTitle;

  /// No description provided for @arIntroStand.
  ///
  /// In en, this message translates to:
  /// **'Stand still in a clear space and turn on the spot to look around. Do not walk while practising.'**
  String get arIntroStand;

  /// No description provided for @arTrackingSensor.
  ///
  /// In en, this message translates to:
  /// **'Move your phone to look around'**
  String get arTrackingSensor;

  /// No description provided for @arTrackingTouch.
  ///
  /// In en, this message translates to:
  /// **'Drag the screen to look around'**
  String get arTrackingTouch;

  /// No description provided for @arStart.
  ///
  /// In en, this message translates to:
  /// **'Start practice'**
  String get arStart;

  /// No description provided for @arRecenter.
  ///
  /// In en, this message translates to:
  /// **'Face forward'**
  String get arRecenter;

  /// No description provided for @arSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get arSelect;

  /// No description provided for @arFound.
  ///
  /// In en, this message translates to:
  /// **'Found {found} of {total}'**
  String arFound(int found, int total);

  /// No description provided for @arPullPin.
  ///
  /// In en, this message translates to:
  /// **'Pull the pin'**
  String get arPullPin;

  /// No description provided for @arHoldToSpray.
  ///
  /// In en, this message translates to:
  /// **'Hold to spray'**
  String get arHoldToSpray;

  /// No description provided for @arPullPinFirst.
  ///
  /// In en, this message translates to:
  /// **'Pull the pin first'**
  String get arPullPinFirst;

  /// No description provided for @arAimLow.
  ///
  /// In en, this message translates to:
  /// **'Aim lower, at the base of the fire'**
  String get arAimLow;

  /// No description provided for @arSweep.
  ///
  /// In en, this message translates to:
  /// **'Sweep side to side'**
  String get arSweep;

  /// No description provided for @arFireLabel.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get arFireLabel;

  /// No description provided for @arExtinguisherLabel.
  ///
  /// In en, this message translates to:
  /// **'Extinguisher'**
  String get arExtinguisherLabel;

  /// No description provided for @arFireOut.
  ///
  /// In en, this message translates to:
  /// **'Fire is out'**
  String get arFireOut;

  /// No description provided for @arExtinguisherEmpty.
  ///
  /// In en, this message translates to:
  /// **'The extinguisher is empty. Leave the area and raise the alarm.'**
  String get arExtinguisherEmpty;

  /// No description provided for @arFireTooBig.
  ///
  /// In en, this message translates to:
  /// **'The fire is too big. Leave now and raise the alarm.'**
  String get arFireTooBig;

  /// No description provided for @arHoldToMeasure.
  ///
  /// In en, this message translates to:
  /// **'Hold to measure'**
  String get arHoldToMeasure;

  /// No description provided for @arPointAtLevel.
  ///
  /// In en, this message translates to:
  /// **'Point at a level to measure it'**
  String get arPointAtLevel;

  /// No description provided for @arDecideSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe to enter'**
  String get arDecideSafe;

  /// No description provided for @arDecideUnsafe.
  ///
  /// In en, this message translates to:
  /// **'Not safe: ventilate and test again'**
  String get arDecideUnsafe;

  /// No description provided for @arDetectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Gas detector: {level}'**
  String arDetectorTitle(String level);

  /// No description provided for @homeJohar.
  ///
  /// In en, this message translates to:
  /// **'Johar, {name}!'**
  String homeJohar(String name);

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Your safety training'**
  String get progressTitle;

  /// No description provided for @progressCount.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} trainings passed'**
  String progressCount(int done, int total);

  /// No description provided for @sectionTrainings.
  ///
  /// In en, this message translates to:
  /// **'Trainings'**
  String get sectionTrainings;

  /// No description provided for @workersTitle.
  ///
  /// In en, this message translates to:
  /// **'Workers on this phone'**
  String get workersTitle;

  /// No description provided for @addWorker.
  ///
  /// In en, this message translates to:
  /// **'Add a worker'**
  String get addWorker;

  /// No description provided for @certExpiresSoon.
  ///
  /// In en, this message translates to:
  /// **'{module} certificate expires in {days} days'**
  String certExpiresSoon(String module, int days);

  /// No description provided for @certExpiredBanner.
  ///
  /// In en, this message translates to:
  /// **'{module} certificate has expired'**
  String certExpiredBanner(String module);

  /// No description provided for @retakeTraining.
  ///
  /// In en, this message translates to:
  /// **'Retake training'**
  String get retakeTraining;

  /// No description provided for @refresherBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'7-day memory check'**
  String get refresherBannerTitle;

  /// No description provided for @refresherBannerBody.
  ///
  /// In en, this message translates to:
  /// **'{module}: 5 quick questions to see what you remember.'**
  String refresherBannerBody(String module);

  /// No description provided for @refresherStart.
  ///
  /// In en, this message translates to:
  /// **'Start check'**
  String get refresherStart;

  /// No description provided for @refresherResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory check done'**
  String get refresherResultTitle;

  /// No description provided for @refresherRemembered.
  ///
  /// In en, this message translates to:
  /// **'You remembered {score}%'**
  String refresherRemembered(int score);

  /// No description provided for @refresherBefore.
  ///
  /// In en, this message translates to:
  /// **'Right after training: {score}%'**
  String refresherBefore(int score);

  /// No description provided for @refresherGood.
  ///
  /// In en, this message translates to:
  /// **'Well remembered. Keep it up!'**
  String get refresherGood;

  /// No description provided for @refresherRetake.
  ///
  /// In en, this message translates to:
  /// **'Some things were forgotten. Take the training again to refresh them.'**
  String get refresherRetake;

  /// No description provided for @arLookCloser.
  ///
  /// In en, this message translates to:
  /// **'Look closer'**
  String get arLookCloser;

  /// No description provided for @arStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String arStepOf(int current, int total);

  /// No description provided for @arReportHazard.
  ///
  /// In en, this message translates to:
  /// **'Report hazard'**
  String get arReportHazard;

  /// No description provided for @arGoThisWay.
  ///
  /// In en, this message translates to:
  /// **'Go this way'**
  String get arGoThisWay;

  /// No description provided for @arRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get arRemove;

  /// No description provided for @arDoNext.
  ///
  /// In en, this message translates to:
  /// **'Do this next'**
  String get arDoNext;

  /// No description provided for @arClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get arClose;

  /// No description provided for @arSelectedPill.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get arSelectedPill;

  /// No description provided for @arWrongOrder.
  ///
  /// In en, this message translates to:
  /// **'Not yet. Think about what must happen first.'**
  String get arWrongOrder;

  /// No description provided for @narrationListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get narrationListen;

  /// No description provided for @narrationStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get narrationStop;
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
      <String>['en', 'hi', 'sat'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'sat':
      return AppLocalizationsSat();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
