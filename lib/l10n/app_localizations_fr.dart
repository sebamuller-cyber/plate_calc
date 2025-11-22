// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Calculateur de plaques';

  @override
  String get unitsLabel => 'Unités :';

  @override
  String get barLabel => 'Barre';

  @override
  String get collarsLabel => 'Collets';

  @override
  String get interpretRmAs => 'Interpréter RM% comme :';

  @override
  String get modeTotalInclBar => 'Total (barre incluse)';

  @override
  String get modePerSide => 'Par côté (sans la barre)';

  @override
  String get rmFieldNoMovement => 'Ton 1RM';

  @override
  String rmFieldWithMovement(String movementName) {
    return '1RM de $movementName';
  }

  @override
  String get percentLabel => 'Pourcentage';

  @override
  String derivedTargetLabel(String percent) {
    return 'Objectif dérivé de $percent % du RM :';
  }

  @override
  String derivedTotal(String weight, String units) {
    return 'TOTAL : $weight $units';
  }

  @override
  String derivedPerSide(String weight, String units) {
    return 'PAR CÔTÉ (disques) : $weight $units';
  }

  @override
  String get percentTableTitle => 'Tableau des pourcentages (touche pour appliquer)';

  @override
  String get percentTableHeaderPercent => '%';

  @override
  String get percentTableHeaderTotal => 'Total';

  @override
  String get percentTableHeaderPerSide => 'Par côté (sans la barre)';

  @override
  String get calculateButton => 'Calculer la répartition des plaques';

  @override
  String get historyButton => 'Historique de RM';

  @override
  String historySheetTitle(String movementName, String units) {
    return 'Historique de RM — $movementName ($units)';
  }

  @override
  String get historyClear => 'Effacer';

  @override
  String get historyEmpty => 'Aucun enregistrement pour l’instant. Enregistre un RM pour créer des entrées.';

  @override
  String get historyClearedSnack => 'Historique effacé.';

  @override
  String historyRowRm(String rm, String units) {
    return 'RM : $rm $units';
  }

  @override
  String get saveRmTooltip => 'Enregistrer le RM';

  @override
  String get saveRmInvalidSnack => 'Entre un RM valide avant d’enregistrer.';

  @override
  String saveRmOkSnack(String movementName, String units) {
    return 'RM enregistré pour $movementName ($units).';
  }

  @override
  String get deleteMovementDialogTitle => 'Supprimer le mouvement';

  @override
  String deleteMovementDialogContent(String movementName) {
    return 'Supprimer « $movementName » complètement ? Il sera retiré de ta liste ainsi que son RM / historique.';
  }

  @override
  String get deleteMovementCancel => 'Annuler';

  @override
  String get deleteMovementConfirm => 'Supprimer';

  @override
  String deleteMovementButton(String movementName) {
    return 'Supprimer $movementName';
  }

  @override
  String deleteMovementOkSnack(String movementName) {
    return 'Mouvement supprimé : $movementName';
  }

  @override
  String get deleteMovementFailSnack => 'Impossible de supprimer.';

  @override
  String get errorPercentInvalid => 'Entre un pourcentage valide (> 0).';

  @override
  String get errorTargetTooLow => 'L’objectif est inférieur au poids de la barre ou les données ne sont pas valides.';

  @override
  String get panelCloseTooltip => 'Fermer';

  @override
  String resultExact(String weight, String units) {
    return 'Atteint : $weight $units (exact)';
  }

  @override
  String resultApprox(String weight, String shortfall, String units) {
    return 'Meilleure approximation : $weight $units (il manque $shortfall $units)';
  }

  @override
  String get chosenDiscsTitle => 'Plaques choisies (totales) :';

  @override
  String get yourLiftsTitle => 'Tes mouvements';

  @override
  String get addLiftTitle => 'Ajouter un mouvement';

  @override
  String get addLiftHint => 'Ex.: Front Squat';

  @override
  String get saveLabel => 'Enregistrer';

  @override
  String get noRmLabel => 'Sans RM';

  @override
  String get rmDetailNewRmLabel => 'Nouveau RM';

  @override
  String get rmDetailNewRmHint => 'Ex : 150.5';

  @override
  String get rmSavedSnack => 'RM enregistré.';

  @override
  String get deleteRecordDialogTitle => 'Supprimer l’enregistrement';

  @override
  String get deleteRecordDialogContent => 'Supprimer cet enregistrement de l’historique ?';

  @override
  String get deleteRecordTooltip => 'Supprimer l’enregistrement';

  @override
  String get clearHistoryDialogTitle => 'Effacer l’historique';

  @override
  String get clearHistoryDialogContent => 'Supprimer tout l’historique de ce mouvement ?';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsTabLanguage => 'Langue';

  @override
  String get settingsTabInventory => 'Inventaire';

  @override
  String get settingsLanguageTitle => 'Langue de l’application';

  @override
  String get settingsLanguageSystem => 'Utiliser la langue du système';

  @override
  String get settingsLanguageSpanish => 'Espagnol';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageEnglish => 'Anglais';

  @override
  String get inventoryKgTitle => 'Disques en kg';

  @override
  String get inventoryLbTitle => 'Disques en lb';

  @override
  String get inventorySaveButton => 'Enregistrer l’inventaire';
}
