// Imports exercise demos from a checkout of the web app
// (https://github.com/its-ash/workout.itsash.in).
//
//   dart run tool/import_web.dart /path/to/workout.itsash.in
//
// Runs the demo matcher for every line of every session, then writes
// `assets/data/demos.json` and copies only the GIFs that are used (matched
// exercises and the stretching routine) into `assets/gifs/`. The full
// dataset (1324 GIFs, 125 MB) stays out of the APK.
import 'dart:convert';
import 'dart:io';

import 'package:workout/core/matcher.dart';
import 'package:workout/core/plan.dart';
import 'package:workout/core/sessions.dart';
import 'package:workout/core/stretches.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/import_web.dart <web repo checkout>');
    exit(64);
  }
  final data = Directory('${args.single}/public/data');
  final raw = (jsonDecode(File('${data.path}/exercises.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final db = [
    for (final r in raw)
      ExerciseRecord(
        name: r['name'] as String,
        bodyPart: r['body_part'] as String,
        target: r['target'] as String,
        equipment: r['equipment'] as String,
        secondaryMuscles: (r['secondary_muscles'] as List).cast<String>(),
      ),
  ];

  final demos = <String, String>{};
  final exercises = <String, Map<String, dynamic>>{};
  final gifs = <String>{};
  final missing = <String>{};

  for (final s in workoutSessions) {
    for (final line in s.workout) {
      final name = WorkoutLine.parse(line).name;
      final key = '${s.type.name}|$name';
      if (demos.containsKey(key)) continue;
      final i = findExercise(name, s.type, db);
      if (i == null) {
        if (name != runWalkName) missing.add(key);
        continue;
      }
      final r = raw[i];
      final id = r['id'] as String;
      final gif = (r['gif_url'] as String).split('/').last;
      demos[key] = id;
      gifs.add(gif);
      exercises[id] = {
        'name': r['name'],
        'target': r['target'],
        'equipment': r['equipment'],
        'secondary': r['secondary_muscles'],
        'steps': {'en': (r['instruction_steps'] as Map)['en'], 'hi': (r['instruction_steps'] as Map)['hi']},
        'gif': gif,
      };
    }
  }
  gifs.addAll(stretchingRoutine.map((s) => s.gif));

  final out = Directory('assets/gifs');
  if (out.existsSync()) out.deleteSync(recursive: true);
  out.createSync(recursive: true);
  var bytes = 0;
  for (final g in gifs) {
    final src = File('${data.path}/videos/$g');
    src.copySync('${out.path}/$g');
    bytes += src.lengthSync();
  }

  final attribution = raw.first['attribution'];
  Directory('assets/data').createSync(recursive: true);
  File('assets/data/demos.json').writeAsStringSync(
    const JsonEncoder.withIndent(' ').convert({
      'attribution': attribution,
      'demos': Map.fromEntries(demos.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
      'exercises': Map.fromEntries(exercises.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
    }),
  );

  stdout.writeln(
    '${demos.length} lines matched to ${exercises.length} exercises; '
    '${gifs.length} GIFs, ${(bytes / 1e6).toStringAsFixed(1)} MB',
  );
  if (missing.isNotEmpty) stdout.writeln('No demo: ${missing.join(', ')}');
}
