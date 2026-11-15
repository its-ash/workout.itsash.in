/// Finds the demo exercise in the dataset for a workout line name. A straight
/// port of `findGifForWorkout` in the web app, so both pick the same demo.
/// Runs at import time (`tool/import_web.dart`); the app ships the result.
library;

import 'sessions.dart';

class ExerciseRecord {
  const ExerciseRecord({
    required this.name,
    required this.bodyPart,
    required this.target,
    required this.equipment,
    required this.secondaryMuscles,
  });

  final String name;
  final String bodyPart;
  final String target;
  final String equipment;
  final List<String> secondaryMuscles;
}

String normalizeName(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

String singularize(String w) => w.length > 4 && w.endsWith('s') && !w.endsWith('ss') ? w.substring(0, w.length - 1) : w;

const _sessionBodyParts = {
  SessionType.push: {'chest', 'shoulders', 'upper arms'},
  SessionType.pull: {'back', 'upper arms'},
  SessionType.legs: {'upper legs', 'lower legs', 'waist'},
};

const _sessionTargets = {
  SessionType.push: {'pectorals', 'delts', 'triceps', 'abs'},
  SessionType.pull: {'lats', 'biceps', 'traps', 'upper back', 'forearms', 'abs'},
  SessionType.legs: {'quads', 'hamstrings', 'glutes', 'calves', 'abs'},
};

const _keywordHints = <String, (String, String)>{
  'close grip bench press': ('upper arms', 'triceps'),
  'incline bench press': ('chest', 'pectorals'),
  'bench press': ('chest', 'pectorals'),
  'chest press': ('chest', 'pectorals'),
  'chest fly': ('chest', 'pectorals'),
  'incline fly': ('chest', 'pectorals'),
  'cable fly': ('chest', 'pectorals'),
  'crossover': ('chest', 'pectorals'),
  'reverse pec deck': ('shoulders', 'delts'),
  'pec deck': ('shoulders', 'delts'),
  'overhead press': ('shoulders', 'delts'),
  'shoulder press': ('shoulders', 'delts'),
  'lateral raise': ('shoulders', 'delts'),
  'front raise': ('shoulders', 'delts'),
  'face pull': ('shoulders', 'delts'),
  'reverse fly': ('shoulders', 'delts'),
  'shrug': ('shoulders', 'traps'),
  'hammer curl': ('upper arms', 'biceps'),
  'preacher curl': ('upper arms', 'biceps'),
  'concentration curl': ('upper arms', 'biceps'),
  'curl': ('upper arms', 'biceps'),
  'triceps extension': ('upper arms', 'triceps'),
  'triceps pushdown': ('upper arms', 'triceps'),
  'tricep pushdown': ('upper arms', 'triceps'),
  'triceps': ('upper arms', 'triceps'),
  'tricep': ('upper arms', 'triceps'),
  'pushdown': ('upper arms', 'triceps'),
  'skull crusher': ('upper arms', 'triceps'),
  'overhead extension': ('upper arms', 'triceps'),
  'extension': ('upper arms', 'triceps'),
  'kickback': ('upper arms', 'triceps'),
  'dip': ('upper arms', 'triceps'),
  'pulldown': ('back', 'lats'),
  'pull-up': ('back', 'lats'),
  'pull up': ('back', 'lats'),
  'chin-up': ('back', 'lats'),
  'chin up': ('back', 'lats'),
  'row': ('back', 'upper back'),
  'romanian deadlift': ('upper legs', 'hamstrings'),
  'deadlift': ('upper legs', 'glutes'),
  'squat': ('upper legs', 'quads'),
  'leg press': ('upper legs', 'quads'),
  'lunge': ('upper legs', 'quads'),
  'leg curl': ('upper legs', 'hamstrings'),
  'leg extension': ('upper legs', 'quads'),
  'calf raise': ('lower legs', 'calves'),
  'calf': ('lower legs', 'calves'),
  'crunch': ('waist', 'abs'),
  'plank': ('waist', 'abs'),
  'twist': ('waist', 'abs'),
  'pallof press': ('waist', 'abs'),
  'pallof': ('waist', 'abs'),
  'dragon flag': ('waist', 'abs'),
  'leg raise': ('waist', 'abs'),
  'hip raise': ('waist', 'abs'),
};

const _equipmentHints = <String, List<String>>{
  'barbell': ['barbell', 'olympic barbell', 'trap bar'],
  'dumbbell': ['dumbbell'],
  'cable': ['cable'],
  'ez bar': ['ez barbell'],
  'machine': ['leverage machine', 'sled machine', 'smith machine'],
  'band': ['band', 'resistance band'],
  'kettlebell': ['kettlebell'],
  'rope': ['rope'],
};

const _synonyms = <String, List<String>>{
  'face pull': ['rear delt row'],
  'face pulls': ['rear delt row'],
  'reverse pec deck': ['lever reverse fly'],
  'dip machine': ['lever dip'],
  'chest supported row': ['dumbbell incline row'],
  'seated leg curl': ['lever seated leg curl'],
};

const _noDemo = {'run walk interval protocol'};

List<String> _words(String norm) => norm.split(' ').where((w) => w.isNotEmpty).map(singularize).toList();

/// Index in [db] of the best demo for [workoutName], or null when nothing
/// scores at least 6.
int? findExercise(String workoutName, SessionType type, List<ExerciseRecord> db) {
  final norm = normalizeName(workoutName);
  if (_noDemo.contains(norm)) return null;

  final exact = db.indexWhere((ex) => normalizeName(ex.name) == norm);
  if (exact >= 0) return exact;

  var words = _words(norm);
  final syn = _synonyms[norm];
  if (syn != null) {
    words = {...words, for (final s in syn) ..._words(normalizeName(s))}.toList();
  }
  if (words.isEmpty) return null;

  var bps = {..._sessionBodyParts[type]!};
  var targets = {..._sessionTargets[type]!};
  var kwMatched = false;
  final keys = _keywordHints.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final kw in keys) {
    if (!norm.contains(kw)) continue;
    if (!kwMatched) {
      bps = {};
      targets = {};
      kwMatched = true;
    }
    bps.add(_keywordHints[kw]!.$1);
    targets.add(_keywordHints[kw]!.$2);
  }

  final equip = <String>{
    for (final e in _equipmentHints.entries)
      if (norm.contains(e.key)) ...e.value,
  };

  int? best;
  var bestScore = double.negativeInfinity;
  for (var i = 0; i < db.length; i++) {
    final ex = db[i];
    final exNorm = normalizeName(ex.name);
    final exWords = _words(exNorm);
    var nameScore = 0;
    for (final w in words) {
      if (exNorm.contains(w)) nameScore += w.length > 3 ? 2 : 1;
      if (exWords.contains(w)) nameScore += w.length > 3 ? 1 : 0;
    }
    if (nameScore == 0) continue;
    var score = nameScore.toDouble();
    final bp = bps.contains(ex.bodyPart);
    final tgt = targets.contains(ex.target);
    if (bp) score += 5;
    if (tgt) score += 3;
    if (equip.contains(ex.equipment) && (bp || tgt)) score += 4;
    for (final sm in ex.secondaryMuscles) {
      if (targets.contains(sm.toLowerCase())) score += 1;
    }
    score -= (exWords.length - words.length).clamp(0, 1 << 20) * 0.5;
    // Strictly greater keeps the first of equal scores, like the web's stable sort.
    if (score >= 6 && score > bestScore) {
      best = i;
      bestScore = score;
    }
  }
  return best;
}
