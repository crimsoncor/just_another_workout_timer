import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:prefs/prefs.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
import 'package:uuid/uuid.dart';

import '../generated/l10n.dart';
import '../utils/number_stepper.dart';
import '../utils/storage_helper.dart';
import '../utils/utils.dart';
import '../utils/workout.dart';

class BuilderPage extends StatefulWidget {
  final Workout workout;
  final bool newWorkout;

  const BuilderPage({
    super.key,
    required this.workout,
    required this.newWorkout,
  });

  @override
  BuilderPageState createState() =>
      BuilderPageState(workout, newWorkout: newWorkout);
}

/// page allowing a user to create a workout
class BuilderPageState extends State<BuilderPage> {
  late Workout _workout;
  late String _oldTitle;
  late bool _newWorkout;
  bool _dirty = false;
  int _lastDuration = 30;

  BuilderPageState(Workout workout, {required bool newWorkout}) {
    _workout = workout;
    _oldTitle = _workout.title;
    _newWorkout = newWorkout;
  }

  void _addSet() {
    setState(() {
      var newSet = Set(exercises: []);
      _workout.sets.add(newSet);
      _workout.order.add(newSet.id);
      _dirty = true;
    });
  }

  void addComplex() {
    setState(() {
      var newComplex = Complex(exercises: []);
      _workout.complexes.add(newComplex);
      _workout.order.add(newComplex.id);
      _dirty = true;
    });
  }

  void _deleteByIndex(int index) {
    setState(() {
      _workout.removeByIndex(index);
      _dirty = true;
    });
  }

  void _duplicateByIndex(int index) {
    final grouping = _workout.getByIndex(index);

    switch(grouping) {
      case Set oldSet: {
        var newSet = Set.fromJson(oldSet.toJson());
        newSet.id = const Uuid().v4();
        setState(() {
          final setIndex = _workout.sets.indexOf(oldSet);
          _workout.sets.insert(setIndex + 1, newSet);
          _workout.order.insert(index + 1, newSet.id);
          _dirty = true;
        });
      }
      case Complex oldComplex: {
        var newComplex = Complex.fromJson(oldComplex.toJson());
        newComplex.id = const Uuid().v4();
        setState(() {
          final compIndex = _workout.complexes.indexOf(oldComplex);
          _workout.complexes.insert(compIndex + 1, newComplex);
          _workout.order.insert(index + 1, newComplex.id);
          _dirty = true;
        });
      }
      case null: ;
    }
  }

  void _setAlternating(int setIndex, bool value) {
    setState(() {
      _workout.getByIndex(setIndex)?.alternating = value;
      _dirty = true;
    });
  }

  void _duplicateExercise(int setIndex, int exIndex) {
    switch(_workout.getByIndex(setIndex)) {
      case Set s: {
        var newEx =
          Exercise.fromJson(s.exercises[exIndex].toJson());
        newEx.id = const Uuid().v4();
        setState(() {
          s.exercises.insert(exIndex + 1, newEx);
          _dirty = true;
        });
      }
      case Complex c: {
        var newEx =
          ExerciseWithReps.fromJson(c.exercises[exIndex].toJson());
        newEx.id = const Uuid().v4();
        setState(() {
          c.exercises.insert(exIndex + 1, newEx);
          _dirty = true;
        });
      }
      case null: ;
    }
  }

  void _exerciseAlternating(int setIndex, int exIndex, bool value) {
    setState(() {
      _workout.getByIndex(setIndex)?.setAlternatingByIndex(exIndex, value);
      _dirty = true;
    });
  }

  void saveWorkout() async {
    if (_workout.title == '') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(S.of(context).enterWorkoutName),
        ),
      );
      return;
    }

    setState(() {
      _workout.cleanUp();
    });

    if ((_newWorkout && await workoutExists(_workout.title)) ||
        (!_newWorkout &&
            _oldTitle != _workout.title &&
            await workoutExists(_workout.title))) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(S.of(context).overwriteExistingWorkout),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).no),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(S.of(context).yes),
              onPressed: () async {
                await deleteWorkout(_oldTitle);
                writeWorkout(_workout);
                _oldTitle = _workout.title;
                _newWorkout = false;
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      writeWorkout(_workout);
      _newWorkout = false;
      if (!context.mounted) return;
      Fluttertoast.showToast(
        msg: S.of(context).saved,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _addExercise(int setIndex, bool isRest) {
    setState(() {
      _workout.sets[setIndex].exercises.add(
        Exercise(
          name: isRest ? S.of(context).rest : S.of(context).exercise,
          duration: _lastDuration,
        ),
      );
      _dirty = true;
    });
  }

  void _deleteExercise(int setIndex, int exIndex) {
    setState(() {
      _workout.sets[setIndex].exercises.removeAt(exIndex);
      _dirty = true;
    });
  }

  void _editSetName(int setIndex) async {
    var existingName = _workout.sets[setIndex].name ?? "";
    var newName = await prompt(
        context,
        initialValue: existingName,
        maxLength: 15);
    if (newName != null && newName != existingName) {
      setState(() {
        _workout.sets[setIndex].name = newName.isEmpty ? null : newName;
        _dirty = true;
      });
    }
  }

  Widget _buildSetList() => ReorderableListView(
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            var set = _workout.sets.removeAt(oldIndex);
            _workout.sets.insert(newIndex, set);
          });
        },
        children: _workout.sets
            .asMap()
            .map((index, set) => MapEntry(index, _buildSetItem(set, index)))
            .values
            .toList(),
      );

  Widget _buildSetItem(Set set, int index) =>
      ReorderableDelayedDragStartListener(
        index: index,
        key: Key(set.id),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(
                        set.name ??
                        S.of(context).setIndex(_workout.sets.indexOf(set) + 1),
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      subtitle: Text(Utils.formatSeconds(set.duration)),
                      onLongPress: () {
                        _editSetName(index);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: S.of(context).alternating,
                    onPressed: () =>
                        _setAlternating(index, !set.alternating),
                    isSelected: set.alternating,
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (!states.contains(WidgetState.selected)) {
                          return Theme.of(context).colorScheme.primary.withValues(alpha: 0.38);
                        }
                        return null; // Use the theme's default color
                      }),
                    ),
                  ),
                  Text(S.of(context).repetitions),
                  NumberStepper(
                    lowerLimit: 1,
                    upperLimit: 99,
                    largeSteps: false,
                    step: 1,
                    formatNumber: false,
                    tapToEdit: false,
                    value: set.repetitions,
                    valueChanged: (repetitions) {
                      setState(() {
                        set.repetitions = repetitions;
                        _dirty = true;
                      });
                    },
                  ),
                ],
              ),
              _buildExerciseList(set, index),
              // OverflowBar(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.fitness_center),
                    tooltip: S.of(context).addExercise,
                    onPressed: () {
                      _addExercise(index, false);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.pause_circle_filled),
                    tooltip: S.of(context).addRest,
                    onPressed: () {
                      _addExercise(index, true);
                    },
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(set.hidden ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        set.hidden = !set.hidden;
                        _dirty = true;
                      });
                    },
                  ),
                  IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: S.of(context).deleteSet,
                      onPressed: () {
                        _deleteByIndex(index);
                      }
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: S.of(context).duplicate,
                    onPressed: () => _duplicateByIndex(index),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildExerciseList(Set set, int setIndex) => ReorderableListView(
        shrinkWrap: true,
        primary: false,
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            var ex = _workout.sets[setIndex].exercises.removeAt(oldIndex);
            _workout.sets[setIndex].exercises.insert(newIndex, ex);
          });
        },
        children: set.hidden ? [] : set.exercises
            .asMap()
            .keys
            .map(
              (index) => _buildExerciseItem(
                setIndex,
                index,
                set.exercises[index].name,
                set.exercises[index].alternating,
                set.alternating
              ),
            )
            .toList(),
      );

  Widget _buildExerciseItem(int setIndex, int exIndex, String name, bool alt,
      bool setAlternating) =>
      ReorderableDelayedDragStartListener(
        index: exIndex,
        key: Key(_workout.sets[setIndex].exercises[exIndex].id),
        child: Card(
          child: Row(
            key: Key(_workout.sets[setIndex].exercises[exIndex].id),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ReorderableDragStartListener(
                  index: exIndex,
                  child: const Icon(Icons.drag_handle),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: name,
                      maxLength: 30,
                      inputFormatters: [LengthLimitingTextInputFormatter(30)],
                      maxLines: 1,
                      decoration: InputDecoration(
                        labelText: S.of(context).exercise,
                      ),
                      onChanged: (text) {
                        _workout.sets[setIndex].exercises[exIndex].name = text;
                        _dirty = true;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: S.of(context).deleteExercise,
                          onPressed: () {
                            _deleteExercise(setIndex, exIndex);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: S.of(context).duplicate,
                          onPressed: () =>
                              _duplicateExercise(setIndex, exIndex),
                        ),
                        Spacer(),
                        Visibility(
                          visible: !setAlternating,
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz),
                            tooltip: S.of(context).alternating,
                            onPressed: () =>
                              _exerciseAlternating(setIndex, exIndex, !alt),
                            isSelected: alt,
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.resolveWith((states) {
                                if (!states.contains(WidgetState.selected)) {
                                  return Theme.of(context).colorScheme.primary.withValues(alpha: 0.38);
                                }
                                return null; // Use the theme's default color
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  NumberStepper(
                    lowerLimit: 0,
                    upperLimit: 10800,
                    largeSteps: true,
                    step: Prefs.getInt('spinner_step', 10) ,
                    formatNumber: true,
                    tapToEdit: Prefs.getBool('tap_to_edit', false),
                    value: _workout.sets[setIndex].exercises[exIndex].duration,
                    valueChanged: (duration) {
                      setState(() {
                        _workout.sets[setIndex].exercises[exIndex].duration =
                            duration;
                        _dirty = true;
                        _lastDuration = duration;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          if (!_dirty) {
            return true;
          }

          final value = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              content: Text(S.of(context).exitCheck),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).no),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(S.of(context).yesExit),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          );

          return value!;
        },
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 74,
            elevation: 1,
            title: TextFormField(
              initialValue: _workout.title,
              inputFormatters: [LengthLimitingTextInputFormatter(30)],
              maxLines: 1,
              onChanged: (name) {
                _workout.title = name;
                setState(() {
                  _dirty = true;
                });
              },
              decoration: InputDecoration(
                labelText: S.of(context).name,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: S.of(context).saveWorkout,
                onPressed: saveWorkout,
              ),
            ],
          ),
          body: Center(
            child: _buildSetList(),
          ),
          bottomNavigationBar: BottomAppBar(
            height: 50,
            elevation: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S
                      .of(context)
                      .durationWithTime(Utils.formatSeconds(_workout.duration)),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'mainFAB',
            onPressed: _addSet,
            tooltip: S.of(context).addSet,
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ),
      );
}
