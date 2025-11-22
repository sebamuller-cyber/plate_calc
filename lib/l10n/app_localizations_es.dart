// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Calculadora de Discos';

  @override
  String get unitsLabel => 'Unidades:';

  @override
  String get barLabel => 'Barra';

  @override
  String get collarsLabel => 'Collares';

  @override
  String get interpretRmAs => 'Interpretar RM% como:';

  @override
  String get modeTotalInclBar => 'Total (incluye barra)';

  @override
  String get modePerSide => 'Por lado (sin barra)';

  @override
  String get rmFieldNoMovement => 'Tu 1RM';

  @override
  String rmFieldWithMovement(String movementName) {
    return '1RM de $movementName';
  }

  @override
  String get percentLabel => 'Porcentaje';

  @override
  String derivedTargetLabel(String percent) {
    return 'Objetivo derivado de $percent% del RM:';
  }

  @override
  String derivedTotal(String weight, String units) {
    return 'TOTAL: $weight $units';
  }

  @override
  String derivedPerSide(String weight, String units) {
    return 'POR LADO (discos): $weight $units';
  }

  @override
  String get percentTableTitle => 'Tabla de porcentajes (toca para aplicar)';

  @override
  String get percentTableHeaderPercent => '%';

  @override
  String get percentTableHeaderTotal => 'Total';

  @override
  String get percentTableHeaderPerSide => 'Por lado (sin barra)';

  @override
  String get calculateButton => 'Calcular distribución de discos';

  @override
  String get historyButton => 'Historial RM';

  @override
  String historySheetTitle(String movementName, String units) {
    return 'Historial RM — $movementName ($units)';
  }

  @override
  String get historyClear => 'Limpiar';

  @override
  String get historyEmpty => 'No hay registros aún. Guarda un RM para crear entradas.';

  @override
  String get historyClearedSnack => 'Historial limpiado.';

  @override
  String historyRowRm(String rm, String units) {
    return 'RM: $rm $units';
  }

  @override
  String get saveRmTooltip => 'Guardar RM';

  @override
  String get saveRmInvalidSnack => 'Ingresa un RM válido antes de guardar.';

  @override
  String saveRmOkSnack(String movementName, String units) {
    return 'RM guardado para $movementName ($units).';
  }

  @override
  String get deleteMovementDialogTitle => 'Eliminar movimiento';

  @override
  String deleteMovementDialogContent(String movementName) {
    return '¿Eliminar \"$movementName\" por completo? Se borrará de tu lista y su RM/Historial.';
  }

  @override
  String get deleteMovementCancel => 'Cancelar';

  @override
  String get deleteMovementConfirm => 'Eliminar';

  @override
  String deleteMovementButton(String movementName) {
    return 'Eliminar $movementName';
  }

  @override
  String deleteMovementOkSnack(String movementName) {
    return 'Movimiento eliminado: $movementName';
  }

  @override
  String get deleteMovementFailSnack => 'No se pudo eliminar.';

  @override
  String get errorPercentInvalid => 'Ingresa un porcentaje válido (> 0).';

  @override
  String get errorTargetTooLow => 'El objetivo es menor que la barra o los datos no son válidos.';

  @override
  String get panelCloseTooltip => 'Cerrar';

  @override
  String resultExact(String weight, String units) {
    return 'Alcanzado: $weight $units (exacto)';
  }

  @override
  String resultApprox(String weight, String shortfall, String units) {
    return 'Mejor aproximación: $weight $units (faltan $shortfall $units)';
  }

  @override
  String get chosenDiscsTitle => 'Discos elegidos (totales):';

  @override
  String get yourLiftsTitle => 'Tus movimientos';

  @override
  String get addLiftTitle => 'Agregar movimiento';

  @override
  String get addLiftHint => 'Ej: Front Squat';

  @override
  String get saveLabel => 'Guardar';

  @override
  String get noRmLabel => 'Sin RM';

  @override
  String get rmDetailNewRmLabel => 'Nuevo RM';

  @override
  String get rmDetailNewRmHint => 'Ej: 150.5';

  @override
  String get rmSavedSnack => 'RM guardado.';

  @override
  String get deleteRecordDialogTitle => 'Eliminar registro';

  @override
  String get deleteRecordDialogContent => '¿Eliminar este registro del historial?';

  @override
  String get deleteRecordTooltip => 'Eliminar registro';

  @override
  String get clearHistoryDialogTitle => 'Limpiar historial';

  @override
  String get clearHistoryDialogContent => '¿Eliminar todo el historial de este movimiento?';
}
