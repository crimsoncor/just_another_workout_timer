// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Workout _$WorkoutFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['title', 'sets']);
  return Workout(
    title: json['title'] as String? ?? 'Workout',
    sets: (json['sets'] as List<dynamic>?)
        ?.map((e) => Set.fromJson(e as Map<String, dynamic>))
        .toList(),
    version: (json['version'] as num?)?.toInt() ?? 1,
    position: (json['position'] as num?)?.toInt() ?? -1,
  );
}

Map<String, dynamic> _$WorkoutToJson(Workout instance) => <String, dynamic>{
  'title': instance.title,
  'sets': instance.sets.map((e) => e.toJson()).toList(),
  'version': instance.version,
  'position': instance.position,
};

Set _$SetFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['repetitions', 'exercises']);
  return Set(
    id: json['id'] as String?,
    repetitions: (json['repetitions'] as num?)?.toInt() ?? 1,
    exercises: (json['exercises'] as List<dynamic>?)
        ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList(),
    name: json['name'] as String?,
    hidden: json['hidden'] as bool? ?? false,
    alternating: json['alternating'] as bool? ?? false,
  );
}

Map<String, dynamic> _$SetToJson(Set instance) => <String, dynamic>{
  'repetitions': instance.repetitions,
  'name': instance.name,
  'id': instance.id,
  'exercises': instance.exercises.map((e) => e.toJson()).toList(),
  'hidden': instance.hidden,
  'alternating': instance.alternating,
};

Complex _$ComplexFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['repetitions', 'exercises', 'duration'],
  );
  return Complex(
    id: json['id'] as String?,
    repetitions: (json['repetitions'] as num?)?.toInt() ?? 1,
    exercises: (json['exercises'] as List<dynamic>?)
        ?.map((e) => ExerciseWithReps.fromJson(e as Map<String, dynamic>))
        .toList(),
    duration: (json['duration'] as num?)?.toInt() ?? 180,
    name: json['name'] as String?,
    hidden: json['hidden'] as bool? ?? false,
    alternating: json['alternating'] as bool? ?? false,
  );
}

Map<String, dynamic> _$ComplexToJson(Complex instance) => <String, dynamic>{
  'repetitions': instance.repetitions,
  'name': instance.name,
  'id': instance.id,
  'exercises': instance.exercises.map((e) => e.toJson()).toList(),
  'duration': instance.duration,
  'hidden': instance.hidden,
  'alternating': instance.alternating,
};

Exercise _$ExerciseFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['name', 'duration']);
  return Exercise(
    id: json['id'] as String?,
    name: json['name'] as String? ?? 'Exercise',
    duration: (json['duration'] as num?)?.toInt() ?? 30,
    alternating: json['alternating'] as bool? ?? false,
  );
}

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
  'name': instance.name,
  'id': instance.id,
  'duration': instance.duration,
  'alternating': instance.alternating,
};

ExerciseWithReps _$ExerciseWithRepsFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['name', 'repetitions']);
  return ExerciseWithReps(
    id: json['id'] as String?,
    name: json['name'] as String? ?? 'Exercise',
    repetitions: (json['repetitions'] as num?)?.toInt() ?? 10,
    alternating: json['alternating'] as bool? ?? false,
  );
}

Map<String, dynamic> _$ExerciseWithRepsToJson(ExerciseWithReps instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'repetitions': instance.repetitions,
      'alternating': instance.alternating,
    };

Backup _$BackupFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['workouts']);
  return Backup(
    workouts: (json['workouts'] as List<dynamic>)
        .map((e) => Workout.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$BackupToJson(Backup instance) => <String, dynamic>{
  'workouts': instance.workouts.map((e) => e.toJson()).toList(),
};
