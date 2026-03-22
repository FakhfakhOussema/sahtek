import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum MealType { breakfast, lunch, dinner, snack, mesure }

/// Mode d'interprétation de la mesure glycémie
enum GlycemieMode { directe, convertie }

extension GlycemieModeX on GlycemieMode {
  String get label => this == GlycemieMode.directe ? 'Valeur directe' : 'Valeur convertie (×0.18)';
  IconData get icon => this == GlycemieMode.directe
      ? Icons.straighten_rounded
      : Icons.calculate_rounded;
}

extension MealTypeX on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast: return 'Petit Déjeuner';
      case MealType.lunch:     return 'Déjeuner';
      case MealType.dinner:    return 'Dîner';
      case MealType.snack:     return 'Snack';
      case MealType.mesure:    return 'Mesure capteur';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast: return Icons.free_breakfast_rounded;
      case MealType.lunch:     return Icons.lunch_dining_rounded;
      case MealType.dinner:    return Icons.dinner_dining_rounded;
      case MealType.snack:     return Icons.cookie_rounded;
      case MealType.mesure:    return Icons.sensors_rounded;
    }
  }

  bool get isDeletable =>
      this == MealType.snack || this == MealType.mesure;

  /// Mesure capteur = affichage simplifié, sans section dose
  bool get isSensorOnly => this == MealType.mesure;
}

class MealEntry {
  final String id;
  final String name;
  final MealType type;

  /// Mesure brute saisie par l'utilisateur
  final double? glycemie;

  /// Mode choisi par l'utilisateur — conservé entre les sessions
  final GlycemieMode glycemieMode;

  /// Glucides en grammes
  final double? glucides;

  /// Dose d'insuline saisie directement par l'utilisateur — enregistrée telle quelle
  final double? dose;

  /// Observation libre (texte)
  final String? observation;

  final TimeOfDay? doseTime;
  final TimeOfDay? mealTime;

  MealEntry({
    String? id,
    required this.name,
    required this.type,
    this.glycemie,
    this.glycemieMode = GlycemieMode.directe,
    this.glucides,
    this.dose,
    this.observation,
    this.doseTime,
    this.mealTime,
  }) : id = id ?? const Uuid().v4();

  /// Valeur affichée selon le choix de l'utilisateur :
  ///   directe   → valeur telle quelle
  ///   convertie → valeur × 0.18
  double? get glycemieAffichee {
    if (glycemie == null) return null;
    if (glycemieMode == GlycemieMode.convertie) {
      return double.parse((glycemie! * 0.18).toStringAsFixed(2));
    }
    return double.parse(glycemie!.toStringAsFixed(2));
  }

  String get glycemieUnite =>
      glycemieMode == GlycemieMode.convertie ? 'Mg/dl (converti)' : 'Mg/dl';

  bool get hasGlycemie => glycemie != null && glycemie! > 0;
  bool get hasDose     => dose != null && dose! > 0;

  MealEntry copyWith({
    String? name,
    MealType? type,
    Object? glycemie      = _keep,
    Object? glycemieMode  = _keep,
    Object? glucides      = _keep,
    Object? dose          = _keep,
    Object? observation   = _keep,
    Object? doseTime      = _keep,
    Object? mealTime      = _keep,
  }) {
    return MealEntry(
      id:           id,
      name:         name ?? this.name,
      type:         type ?? this.type,
      glycemie:     identical(glycemie,     _keep) ? this.glycemie     : glycemie     as double?,
      glycemieMode: identical(glycemieMode, _keep) ? this.glycemieMode : glycemieMode as GlycemieMode,
      glucides:     identical(glucides,     _keep) ? this.glucides     : glucides     as double?,
      dose:         identical(dose,         _keep) ? this.dose         : dose         as double?,
      observation:  identical(observation,  _keep) ? this.observation  : observation  as String?,
      doseTime:     identical(doseTime,     _keep) ? this.doseTime     : doseTime     as TimeOfDay?,
      mealTime:     identical(mealTime,     _keep) ? this.mealTime     : mealTime     as TimeOfDay?,
    );
  }

  static const Object _keep = Object();

  Map<String, dynamic> toJson() => {
    'id':           id,
    'name':         name,
    'type':         type.name,
    'glycemie':     glycemie,
    'glycemieMode': glycemieMode.name,
    'glucides':     glucides,
    'dose':         dose,
    'observation':  observation,
    'doseHour':     doseTime?.hour,
    'doseMinute':   doseTime?.minute,
    'mealHour':     mealTime?.hour,
    'mealMinute':   mealTime?.minute,
  };

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
    id:           j['id'] as String,
    name:         j['name'] as String,
    type:         MealType.values.firstWhere((e) => e.name == j['type']),
    glycemie:     (j['glycemie']    as num?)?.toDouble(),
    glycemieMode: GlycemieMode.values.firstWhere(
          (e) => e.name == (j['glycemieMode'] ?? 'directe'),
      orElse: () => GlycemieMode.directe,
    ),
    glucides:     (j['glucides']    as num?)?.toDouble(),
    dose:         (j['dose']        as num?)?.toDouble(),
    observation:  j['observation']  as String?,
    doseTime: j['doseHour'] != null
        ? TimeOfDay(hour: j['doseHour'] as int, minute: j['doseMinute'] as int)
        : null,
    mealTime: j['mealHour'] != null
        ? TimeOfDay(hour: j['mealHour'] as int, minute: j['mealMinute'] as int)
        : null,
  );
}