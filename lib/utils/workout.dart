import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'workout.g.dart';

@JsonSerializable(explicitToJson: true)
class Workout {
  static const fileVersion = 3;

  Workout({
    this.title = 'Workout',
    List<String>? order,
    List<Set>? sets,
    List<Complex>? complexes,
    this.version = fileVersion,
    this.position = -1,
  }) {
    this.sets = sets ?? [Set()];
    this.complexes = complexes ?? [];
    this.order = order ?? [];
  }

  @JsonKey(required: true)
  String title;

  @JsonKey(required: true)
  late List<Set> sets;

  @JsonKey()
  late List<Complex> complexes;

  @JsonKey()
  late List<String> order;

  @JsonKey(defaultValue: 1)
  int version;

  @JsonKey(defaultValue: -1)
  int position;

  int get duration => sets.fold(0, (val, set) => val + set.duration) +
        complexes.fold(0, (val, complex) => val + complex.duration);

  List<NamedGrouping> get orderedGroupings =>
      order.map((id) => getById(id)).nonNulls.toList();

  NamedGrouping? getById(String id) =>
      sets.firstWhereOrNull((s) => s.id == id) ??
          complexes.firstWhereOrNull((c) => c.id == id);

  NamedGrouping? getByIndex(int index) => getById(order[index]);

  NamedGrouping? removeByIndex(int index) {
    final id = order[index];

    final setIndex = sets.indexWhere((s) => s.id == id);
    if (setIndex != -1) {
      order.removeAt(index);
      return sets.removeAt(setIndex);
    }
    final compIndex = complexes.indexWhere((c) => c.id == id);
    if (compIndex != -1) {
      order.removeAt(index);
      return complexes.removeAt(compIndex);
    }
  }

  /// remove sets without any exercises
  void cleanUp() {
    sets.removeWhere((set) => set.exercises.isEmpty);
  }

  factory Workout.fromJson(Map<String, dynamic> json) =>
      _$WorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutToJson(this);
}

sealed class NamedGrouping
{
  String? get name;
  set name(String value);

  String get id;

  bool get alternating;
  set alternating(bool value);

  void setAlternatingByIndex(int exerciseIdx, bool value) {
    switch(this) {
      case Set s: s.exercises[exerciseIdx].alternating = value;
      case Complex c: c.exercises[exerciseIdx].alternating = value;
    }
  }
}

@JsonSerializable(explicitToJson: true)
class Set extends NamedGrouping {
  Set({
    String? id,
    this.repetitions = 1,
    List<Exercise>? exercises,
    this.name,
    this.hidden = false,
    this.alternating = false
  }) {
    this.id = id ?? const Uuid().v4();
    this.exercises = exercises ?? [Exercise()];
  }

  @JsonKey(required: true)
  int repetitions;

  @JsonKey()
  late String? name;

  @JsonKey()
  late String id;

  @JsonKey(required: true)
  late List<Exercise> exercises;

  bool hidden;

  @JsonKey()
  bool alternating;

  int get duration => exercises.fold(0, (val, exercise) => val + exercise.duration);

  factory Set.fromJson(Map<String, dynamic> json) => _$SetFromJson(json);
  Map<String, dynamic> toJson() => _$SetToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Complex extends NamedGrouping {
  Complex({
    String? id,
    this.repetitions = 1,
    List<ExerciseWithReps>? exercises,
    this.length = 180,
    this.name,
    this.hidden = false,
    this.alternating = false
  }) {
    this.id = id ?? const Uuid().v4();
    this.exercises = exercises ?? [ExerciseWithReps()];
  }

  @JsonKey(required: true)
  int repetitions;

  @JsonKey()
  late String? name;

  @JsonKey()
  late String id;

  @JsonKey(required: true)
  late List<ExerciseWithReps> exercises;

  @JsonKey(required: true, defaultValue: 180)
  int length;

  bool hidden;

  @JsonKey()
  bool alternating;

  int get duration => length * repetitions;

  factory Complex.fromJson(Map<String, dynamic> json) => _$ComplexFromJson(json);
  Map<String, dynamic> toJson() => _$ComplexToJson(this);
}

sealed class NamedExercise {
  String get name;

  String get id;

  bool get alternating;

}

@JsonSerializable(explicitToJson: true)
class Exercise extends NamedExercise {
  Exercise({
    String? id,
    this.name = 'Exercise',
    this.duration = 30,
    this.alternating = false
  }) {
    this.id = id ?? const Uuid().v4();
  }

  @JsonKey(required: true)
  String name;

  @JsonKey()
  late String id;

  @JsonKey(required: true, defaultValue: 30)
  int duration;

  @JsonKey()
  bool alternating;

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ExerciseWithReps extends NamedExercise {
  ExerciseWithReps({
    String? id,
    this.name = 'Exercise',
    this.repetitions = 10,
    this.alternating = false
  }) {
    this.id = id ?? const Uuid().v4();
  }

  @JsonKey()
  late String id;

  @JsonKey(required: true)
  String name;

  @JsonKey(required: true, defaultValue: 10)
  int repetitions;

  @JsonKey()
  bool alternating;

  factory ExerciseWithReps.fromJson(Map<String, dynamic> json) =>
      _$ExerciseWithRepsFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseWithRepsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Backup {
  @JsonKey(required: true)
  List<Workout> workouts;

  Backup({required this.workouts});

  factory Backup.fromJson(Map<String, dynamic> json) => _$BackupFromJson(json);
  Map<String, dynamic> toJson() => _$BackupToJson(this);
}
