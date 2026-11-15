import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/sessions.dart';

/// One demo exercise from the bundled dataset (`assets/data/demos.json`).
class Demo {
  const Demo({
    required this.name,
    required this.target,
    required this.equipment,
    required this.secondary,
    required this.steps,
    required this.gif,
  });

  final String name;
  final String target;
  final String equipment;
  final List<String> secondary;

  /// Step-by-step instructions keyed by language (`en`, `hi`).
  final Map<String, List<String>> steps;

  /// Asset path of the animated demo.
  final String gif;

  factory Demo.fromJson(Map<String, dynamic> j) => Demo(
    name: j['name'] as String,
    target: j['target'] as String,
    equipment: j['equipment'] as String,
    secondary: (j['secondary'] as List).cast<String>(),
    steps: {for (final e in (j['steps'] as Map<String, dynamic>).entries) e.key: (e.value as List).cast<String>()},
    gif: 'assets/gifs/${j['gif']}',
  );
}

/// Workout line -> demo, built by `tool/import_web.dart`.
class DemoLibrary {
  const DemoLibrary({required this.demos, required this.attribution});

  const DemoLibrary.empty() : demos = const {}, attribution = '';

  /// Keyed `<split>|<exercise name>`.
  final Map<String, Demo> demos;
  final String attribution;

  Demo? find(SessionType type, String name) => demos['${type.name}|$name'];

  static Future<DemoLibrary> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString('assets/data/demos.json');
    return parse(raw);
  }

  static DemoLibrary parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final exercises = {
      for (final e in (j['exercises'] as Map<String, dynamic>).entries)
        e.key: Demo.fromJson(e.value as Map<String, dynamic>),
    };
    return DemoLibrary(
      attribution: j['attribution'] as String? ?? '',
      demos: {
        for (final e in (j['demos'] as Map<String, dynamic>).entries)
          if (exercises[e.value] != null) e.key: exercises[e.value]!,
      },
    );
  }
}
