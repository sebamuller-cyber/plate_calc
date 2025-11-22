import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Plate Calculator'**
  String get appTitle;

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units:'**
  String get unitsLabel;

  /// No description provided for @barLabel.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get barLabel;

  /// No description provided for @collarsLabel.
  ///
  /// In en, this message translates to:
  /// **'Collars'**
  String get collarsLabel;

  /// No description provided for @interpretRmAs.
  ///
  /// In en, this message translates to:
  /// **'Interpret RM% as:'**
  String get interpretRmAs;

  /// No description provided for @modeTotalInclBar.
  ///
  /// In en, this message translates to:
  /// **'Total (includes bar)'**
  String get modeTotalInclBar;

  /// No description provided for @modePerSide.
  ///
  /// In en, this message translates to:
  /// **'Per side (without bar)'**
  String get modePerSide;

  /// No description provided for @rmFieldNoMovement.
  ///
  /// In en, this message translates to:
  /// **'Your 1RM'**
  String get rmFieldNoMovement;

  /// Label when a movement name exists
  ///
  /// In en, this message translates to:
  /// **'{movementName} 1RM'**
  String rmFieldWithMovement(String movementName);

  /// No description provided for @percentLabel.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get percentLabel;

  /// No description provided for @derivedTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target derived from {percent}% RM:'**
  String derivedTargetLabel(String percent);

  /// No description provided for @derivedTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL: {weight} {units}'**
  String derivedTotal(String weight, String units);

  /// No description provided for @derivedPerSide.
  ///
  /// In en, this message translates to:
  /// **'PER SIDE (plates): {weight} {units}'**
  String derivedPerSide(String weight, String units);

  /// No description provided for @percentTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Percentage table (tap to apply)'**
  String get percentTableTitle;

  /// No description provided for @percentTableHeaderPercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get percentTableHeaderPercent;

  /// No description provided for @percentTableHeaderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get percentTableHeaderTotal;

  /// No description provided for @percentTableHeaderPerSide.
  ///
  /// In en, this message translates to:
  /// **'Per side (without bar)'**
  String get percentTableHeaderPerSide;

  /// No description provided for @calculateButton.
  ///
  /// In en, this message translates to:
  /// **'Calculate plate distribution'**
  String get calculateButton;

  /// No description provided for @historyButton.
  ///
  /// In en, this message translates to:
  /// **'RM History'**
  String get historyButton;

  /// No description provided for @historySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'RM History — {movementName} ({units})'**
  String historySheetTitle(String movementName, String units);

  /// No description provided for @historyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get historyClear;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet. Save an RM to create entries.'**
  String get historyEmpty;

  /// No description provided for @historyClearedSnack.
  ///
  /// In en, this message translates to:
  /// **'History cleared.'**
  String get historyClearedSnack;

  /// No description provided for @historyRowRm.
  ///
  /// In en, this message translates to:
  /// **'RM: {rm} {units}'**
  String historyRowRm(String rm, String units);

  /// No description provided for @saveRmTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save RM'**
  String get saveRmTooltip;

  /// No description provided for @saveRmInvalidSnack.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid RM before saving.'**
  String get saveRmInvalidSnack;

  /// No description provided for @saveRmOkSnack.
  ///
  /// In en, this message translates to:
  /// **'RM saved for {movementName} ({units}).'**
  String saveRmOkSnack(String movementName, String units);

  /// No description provided for @deleteMovementDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete movement'**
  String get deleteMovementDialogTitle;

  /// No description provided for @deleteMovementDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{movementName}\" completely? It will be removed along with its RM/History.'**
  String deleteMovementDialogContent(String movementName);

  /// No description provided for @deleteMovementCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteMovementCancel;

  /// No description provided for @deleteMovementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteMovementConfirm;

  /// No description provided for @deleteMovementButton.
  ///
  /// In en, this message translates to:
  /// **'Delete {movementName}'**
  String deleteMovementButton(String movementName);

  /// No description provided for @deleteMovementOkSnack.
  ///
  /// In en, this message translates to:
  /// **'Movement deleted: {movementName}'**
  String deleteMovementOkSnack(String movementName);

  /// No description provided for @deleteMovementFailSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not delete movement.'**
  String get deleteMovementFailSnack;

  /// No description provided for @errorPercentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid percentage (> 0).'**
  String get errorPercentInvalid;

  /// No description provided for @errorTargetTooLow.
  ///
  /// In en, this message translates to:
  /// **'Target is below bar weight or the data is invalid.'**
  String get errorTargetTooLow;

  /// No description provided for @panelCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get panelCloseTooltip;

  /// No description provided for @resultExact.
  ///
  /// In en, this message translates to:
  /// **'Reached: {weight} {units} (exact)'**
  String resultExact(String weight, String units);

  /// No description provided for @resultApprox.
  ///
  /// In en, this message translates to:
  /// **'Best approximation: {weight} {units} (short by {shortfall} {units})'**
  String resultApprox(String weight, String shortfall, String units);

  /// No description provided for @chosenDiscsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chosen discs (total):'**
  String get chosenDiscsTitle;

  /// No description provided for @yourLiftsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your lifts'**
  String get yourLiftsTitle;

  /// No description provided for @addLiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Add movement'**
  String get addLiftTitle;

  /// No description provided for @addLiftHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Front Squat'**
  String get addLiftHint;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @noRmLabel.
  ///
  /// In en, this message translates to:
  /// **'No RM'**
  String get noRmLabel;

  /// No description provided for @rmDetailNewRmLabel.
  ///
  /// In en, this message translates to:
  /// **'New RM'**
  String get rmDetailNewRmLabel;

  /// No description provided for @rmDetailNewRmHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: 150.5'**
  String get rmDetailNewRmHint;

  /// No description provided for @rmSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'RM saved.'**
  String get rmSavedSnack;

  /// No description provided for @deleteRecordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get deleteRecordDialogTitle;

  /// No description provided for @deleteRecordDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Delete this record from history?'**
  String get deleteRecordDialogContent;

  /// No description provided for @deleteRecordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get deleteRecordTooltip;

  /// No description provided for @clearHistoryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistoryDialogTitle;

  /// No description provided for @clearHistoryDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Delete all history for this lift?'**
  String get clearHistoryDialogContent;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTabLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsTabLanguage;

  /// No description provided for @settingsTabInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get settingsTabInventory;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Use system language'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get settingsLanguageSpanish;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get settingsLanguageFrench;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @inventoryKgTitle.
  ///
  /// In en, this message translates to:
  /// **'Plates in kg'**
  String get inventoryKgTitle;

  /// No description provided for @inventoryLbTitle.
  ///
  /// In en, this message translates to:
  /// **'Plates in lb'**
  String get inventoryLbTitle;

  /// No description provided for @inventorySaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save inventory'**
  String get inventorySaveButton;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
