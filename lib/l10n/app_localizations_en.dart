// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plate Calculator';

  @override
  String get unitsLabel => 'Units:';

  @override
  String get barLabel => 'Bar';

  @override
  String get collarsLabel => 'Collars';

  @override
  String get interpretRmAs => 'Interpret RM% as:';

  @override
  String get modeTotalInclBar => 'Total (includes bar)';

  @override
  String get modePerSide => 'Per side (without bar)';

  @override
  String get rmFieldNoMovement => 'Your 1RM';

  @override
  String rmFieldWithMovement(String movementName) {
    return '$movementName 1RM';
  }

  @override
  String get percentLabel => 'Percent';

  @override
  String derivedTargetLabel(String percent) {
    return 'Target derived from $percent% RM:';
  }

  @override
  String derivedTotal(String weight, String units) {
    return 'TOTAL: $weight $units';
  }

  @override
  String derivedPerSide(String weight, String units) {
    return 'PER SIDE (plates): $weight $units';
  }

  @override
  String get percentTableTitle => 'Percentage table (tap to apply)';

  @override
  String get percentTableHeaderPercent => '%';

  @override
  String get percentTableHeaderTotal => 'Total';

  @override
  String get percentTableHeaderPerSide => 'Per side (without bar)';

  @override
  String get calculateButton => 'Calculate plate distribution';

  @override
  String get historyButton => 'RM History';

  @override
  String historySheetTitle(String movementName, String units) {
    return 'RM History — $movementName ($units)';
  }

  @override
  String get historyClear => 'Clear';

  @override
  String get historyEmpty => 'No records yet. Save an RM to create entries.';

  @override
  String get historyClearedSnack => 'History cleared.';

  @override
  String historyRowRm(String rm, String units) {
    return 'RM: $rm $units';
  }

  @override
  String get saveRmTooltip => 'Save RM';

  @override
  String get saveRmInvalidSnack => 'Enter a valid RM before saving.';

  @override
  String saveRmOkSnack(String movementName, String units) {
    return 'RM saved for $movementName ($units).';
  }

  @override
  String get deleteMovementDialogTitle => 'Delete movement';

  @override
  String deleteMovementDialogContent(String movementName) {
    return 'Delete \"$movementName\" completely? It will be removed along with its RM/History.';
  }

  @override
  String get deleteMovementCancel => 'Cancel';

  @override
  String get deleteMovementConfirm => 'Delete';

  @override
  String deleteMovementButton(String movementName) {
    return 'Delete $movementName';
  }

  @override
  String deleteMovementOkSnack(String movementName) {
    return 'Movement deleted: $movementName';
  }

  @override
  String get deleteMovementFailSnack => 'Could not delete movement.';

  @override
  String get errorPercentInvalid => 'Enter a valid percentage (> 0).';

  @override
  String get errorTargetTooLow => 'Target is below bar weight or the data is invalid.';

  @override
  String get panelCloseTooltip => 'Close';

  @override
  String resultExact(String weight, String units) {
    return 'Reached: $weight $units (exact)';
  }

  @override
  String resultApprox(String weight, String shortfall, String units) {
    return 'Best approximation: $weight $units (short by $shortfall $units)';
  }

  @override
  String get chosenDiscsTitle => 'Chosen discs (total):';

  @override
  String get yourLiftsTitle => 'Your lifts';

  @override
  String get addLiftTitle => 'Add movement';

  @override
  String get addLiftHint => 'Ex: Front Squat';

  @override
  String get saveLabel => 'Save';

  @override
  String get noRmLabel => 'No RM';

  @override
  String get rmDetailNewRmLabel => 'New RM';

  @override
  String get rmDetailNewRmHint => 'Ex: 150.5';

  @override
  String get rmSavedSnack => 'RM saved.';

  @override
  String get deleteRecordDialogTitle => 'Delete record';

  @override
  String get deleteRecordDialogContent => 'Delete this record from history?';

  @override
  String get deleteRecordTooltip => 'Delete record';

  @override
  String get clearHistoryDialogTitle => 'Clear history';

  @override
  String get clearHistoryDialogContent => 'Delete all history for this lift?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTabLanguage => 'Language';

  @override
  String get settingsTabInventory => 'Inventory';

  @override
  String get settingsLanguageTitle => 'App Language';

  @override
  String get settingsLanguageSystem => 'Use system language';

  @override
  String get settingsLanguageSpanish => 'Spanish';

  @override
  String get settingsLanguageFrench => 'French';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get inventoryKgTitle => 'Plates in kg';

  @override
  String get inventoryLbTitle => 'Plates in lb';

  @override
  String get inventorySaveButton => 'Save inventory';
}
