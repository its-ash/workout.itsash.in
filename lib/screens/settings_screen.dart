import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../data/demos.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.demos});

  final DemoLibrary demos;

  @override
  Widget build(BuildContext context) {
    return UiScaffold(
      appBar: const UiAppBar(title: 'Settings'),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UiListGroup(
            header: 'Program',
            footer:
                'Sets, reps, RIR (reps in reserve) and rest times follow evidence-based hypertrophy '
                'guidelines. The session length is an estimate: 40 seconds per set plus rest.',
            children: [
              UiListTile(
                'Push / Pull / Legs',
                subtitle: 'Six variations per split. Shuffle or step through them on the home screen.',
                icon: Icons.fitness_center_rounded,
              ),
              UiListTile(
                'Timers keep counting',
                subtitle:
                    'The session clock and treadmill timers run from the start time, so closing the app '
                    'does not lose your place. The screen stays on during a session.',
                icon: Icons.timer_outlined,
                maxSubtitleLines: 6,
              ),
            ],
          ),
          const UiGap(UiSpace.lg),
          UiListGroup(
            header: 'Privacy',
            children: [
              const UiListTile(
                'Everything stays on this phone',
                subtitle:
                    'No account, no ads, no tracking. Workout uses the internet only to check for app '
                    'updates. "Export to Calendar" hands the session to your calendar app and saves the summary image to '
                    'Pictures/Workout.',
                icon: Icons.lock_rounded,
                iconStatus: UiStatus.success,
                maxSubtitleLines: 6,
              ),
              if (demos.attribution.isNotEmpty)
                UiListTile(
                  'Exercise demos',
                  subtitle: demos.attribution,
                  icon: Icons.movie_outlined,
                  iconStatus: UiStatus.neutral,
                ),
            ],
          ),
          const UiGap(UiSpace.lg),
          const UiAppearanceSection(),
          const UiGap(UiSpace.lg),
          const UiUpdateSection(storeId: 'workout', repo: 'workout.itsash.in'),
          const UiGap(UiSpace.lg),
          const UiDeveloperSection(),
        ],
      ),
    );
  }
}
