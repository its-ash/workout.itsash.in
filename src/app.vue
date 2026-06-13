<!-- eslint-disable @stylistic/quotes -->
<template>
  <main class="app-shell">
    <header class="topbar glass">
      <div class="brand-left">
        <h1>Daily Split Tracker</h1>
      </div>
      <div class="header-actions">
        <div class="badge level-picker">
          <span>Level</span>
          <select v-model="state.level" class="level-select">
            <option v-for="level in levels" :key="level" :value="level">
              {{ level }}
            </option>
          </select>
        </div>
      </div>
    </header>

    <section class="workspace">
      <div class="content-stack">
        <section class="day-card">
          <ul class="workouts">
            <li v-for="item in detailedWorkout" :key="item.name + item.plan">
              <p class="workout-name">{{ item.name }}</p>
              <p class="workout-plan">{{ item.plan }}</p>
              <p class="workout-note">{{ item.note }}</p>
            </li>
          </ul>
        </section>
      </div>
    </section>

    <div class="actions day-actions">
      <button
        v-if="canInstall"
        class="secondary"
        @click="installApp"
      >
        Install App
      </button>
      <button :style="{'width': canInstall ? 'auto' : '100%' }" class="primary" :disabled="isDoneToday" @click="completeDay">
        {{ isDoneToday ? "Completed" : "Complete Day" }}
      </button>
    </div>

    <section v-if="showUpdateBanner" class="update-toast">
      <p class="update-copy">A new version is ready.</p>
      <div class="update-actions">
        <button class="secondary" @click="dismissUpdate">Later</button>
        <button class="primary" @click="applyUpdate">Update Now</button>
      </div>
    </section>

  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, unref, watch } from "vue";

type SplitDay = { day: number; workout: string[] };
type SplitProgram = { id: string; title: string; days: SplitDay[] };
type LevelName = "Beginner" | "Intermediate" | "Advanced";
type WorkoutState = {
  level: LevelName;
  currentDay: number;
  completedDays: number[];
};
type WorkoutLine = { name: string; plan: string; note: string };

const levels: LevelName[] = ["Beginner", "Intermediate", "Advanced"];
const DAYS_PER_CYCLE = 6;

const pushPullLegsSplit: SplitProgram = {
  id: "push-pull-legs",
  title: "Push / Pull / Legs",
  days: [
    {
      day: 1,
      workout: [
        "Smith Machine Incline Press - 4 sets x 8 reps, rest 120s",
        "Dumbbell Bench Press - 3 sets x 10 reps, rest 90s",
        "Incline Cable Flye - 3 sets x 12 reps, rest 60s",
        "Standing Overhead Press - 3 sets x 8 reps, rest 120s",
        "Dumbbell Lateral Raise - 3 sets x 12 reps, rest 60s",
        "Skull Crusher - 3 sets x 10 reps, rest 75s",
        "Rope Triceps Pushdown - 3 sets x 12 reps, rest 60s",
        "Machine Ab Crunch - 3 sets x 12 reps, rest 60s",
      ],
    },
    {
      day: 2,
      workout: [
        "Assisted Chin-up Machine - 4 sets x 8 reps, rest 120s",
        "Barbell Pendlay Row - 4 sets x 8 reps, rest 120s",
        "Machine Row - 3 sets x 12 reps, rest 90s",
        "Lat Pulldown - 3 sets x 10 reps, rest 90s",
        "Face Pulls - 3 sets x 15 reps, rest 60s",
        "Barbell Curl - 3 sets x 8 reps, rest 75s",
        "Machine Curl - 3 sets x 12 reps, rest 60s",
        "Pallof Press - 3 sets x 12 reps each side, rest 60s",
      ],
    },
    {
      day: 3,
      workout: [
        "Barbell Front Squat - 4 sets x 8 reps, rest 150s",
        "Barbell Hip Thrust - 4 sets x 8 reps, rest 120s",
        "Leg Press - 3 sets x 12 reps, rest 120s",
        "Leg Curl - 3 sets x 12 reps, rest 90s",
        "Leg Extension - 3 sets x 15 reps, rest 75s",
        "Standing Calf Raise - 3 sets x 15 reps, rest 60s",
        "Dragon Flag Progression - 3 sets x 6 reps, rest 90s",
      ],
    },
    {
      day: 4,
      workout: [
        "Dumbbell Incline Press - 4 sets x 10 reps, rest 90s",
        "Machine Chest Press - 3 sets x 12 reps, rest 75s",
        "Cable Flye - 3 sets x 15 reps, rest 60s",
        "Dumbbell Lateral Raise - 3 sets x 12 reps, rest 75s",
        "Reverse Pec Deck - 3 sets x 15 reps, rest 60s",
        "Cable Rope Triceps Pushdown - 3 sets x 12 reps, rest 60s",
        "Dip Machine - 3 sets x 10 reps, rest 75s",
        "Suitcase Carry - 3 sets x 45 seconds each side, rest 45s",
      ],
    },
    {
      day: 5,
      workout: [
        "Lat Pulldown - 4 sets x 10 reps, rest 90s",
        "Sealed Chest Supported Row - 4 sets x 10 reps, rest 90s",
        "Incline Dumbbell Curl - 3 sets x 10 reps, rest 75s",
        "Machine Curl - 3 sets x 12 reps, rest 75s",
        "Reverse Cable Curl - 3 sets x 12 reps, rest 60s",
        "Face Pulls - 3 sets x 15 reps, rest 60s",
        "Ab Wheel - 3 sets x 10 reps, rest 60s",
      ],
    },
    {
      day: 6,
      workout: [
        "Bulgarian Split Squat - 4 sets x 10 reps each leg, rest 90s",
        "Leg Press - 3 sets x 12 reps, rest 90s",
        "Leg Extension - 3 sets x 15 reps, rest 75s",
        "Walking Lunge - 3 sets x 10 reps each leg, rest 75s",
        "Seated Calf Raise - 4 sets x 15 reps, rest 60s",
        "Leg Curl - 3 sets x 12 reps, rest 60s",
        "Cable Crunch - 3 sets x 15 reps, rest 60s",
      ],
    },
  ],
};

const STORE_KEY = "workout-pwa-v1";

const state = reactive<WorkoutState>({
  level: levels[0],
  currentDay: 1,
  completedDays: [],
});

const cycleDays = computed<SplitDay[]>(() => {
  const sourceDays = pushPullLegsSplit.days;
  return Array.from({ length: DAYS_PER_CYCLE }, (_, index) => {
    const source = sourceDays[index % sourceDays.length];
    return {
      day: index + 1,
      workout: source.workout,
    };
  });
});
const todayWorkout = computed(
  () => cycleDays.value.find((d) => d.day === state.currentDay)?.workout || [],
);
const isDoneToday = computed(() =>
  state.completedDays.includes(state.currentDay),
);
const pwa = usePWA() as unknown as {
  showInstallPrompt?: unknown;
  isInstalled?: unknown;
  isPWAInstalled?: unknown;
  needRefresh?: unknown;
  updateServiceWorker?: (reloadPage?: boolean) => Promise<unknown>;
  install?: () => Promise<unknown>;
};
const standaloneMode = ref(false);
const dismissUpdateBanner = ref(false);

const updateStandaloneMode = () => {
  if (!import.meta.client) {
    standaloneMode.value = false;
    return;
  }
  standaloneMode.value =
    window.matchMedia("(display-mode: standalone)").matches ||
    // iOS Safari standalone flag.
    Boolean(
      (window.navigator as Navigator & { standalone?: boolean }).standalone,
    );
};

const canInstall = computed(() => {
  const showInstallPrompt = Boolean(unref(pwa?.showInstallPrompt));
  const installed = isInstalled.value;
  return (
    import.meta.client &&
    showInstallPrompt &&
    typeof pwa.install === "function" &&
    !installed &&
    !standaloneMode.value
  );
});

const isInstalled = computed(
  () => Boolean(unref(pwa?.isInstalled)) || Boolean(unref(pwa?.isPWAInstalled)),
);

const installApp = async () => {
  if (!canInstall.value || !pwa.install) {
    return;
  }
  await pwa.install();
};

const hasPendingUpdate = computed(() => Boolean(unref(pwa?.needRefresh)));

const showUpdateBanner = computed(
  () =>
    import.meta.client && hasPendingUpdate.value && !dismissUpdateBanner.value,
);

const dismissUpdate = () => {
  dismissUpdateBanner.value = true;
};

const applyUpdate = async () => {
  if (typeof pwa.updateServiceWorker === "function") {
    await pwa.updateServiceWorker(true);
    return;
  }
  if (import.meta.client) {
    window.location.reload();
  }
};

const levelProfiles: Record<
  LevelName,
  {
    setDelta: number;
    repDelta: number;
    restDelta: number;
    roundDelta: number;
    holdDelta: number;
    effort: string;
    notes: string[];
    fallback: string;
  }
> = {
  Beginner: {
    setDelta: -1,
    repDelta: 2,
    restDelta: 15,
    roundDelta: 0,
    holdDelta: -5,
    effort: "RIR 2-3",
    notes: [
      "Prioritize technique and stable range of motion.",
      "Keep one to three reps in reserve each set.",
      "Rest fully so each set stays clean and repeatable.",
    ],
    fallback: "Use controlled tempo and stop with 2-3 reps in reserve.",
  },
  Intermediate: {
    setDelta: 0,
    repDelta: 0,
    restDelta: 0,
    roundDelta: 1,
    holdDelta: 0,
    effort: "RIR 1-2",
    notes: [
      "Progress load only when all reps are technically strong.",
      "Control eccentric phase and drive explosive concentric reps.",
      "Match effort across sets and keep execution consistent.",
    ],
    fallback: "Target 1-2 reps in reserve with strict, consistent form.",
  },
  Advanced: {
    setDelta: 1,
    repDelta: -1,
    restDelta: -10,
    roundDelta: 1,
    holdDelta: 5,
    effort: "RIR 0-1",
    notes: [
      "Push top sets close to failure while preserving mechanics.",
      "Use full intent on every rep and track performance precisely.",
      "Shorten rest only if output and technique stay high.",
    ],
    fallback: "Train close to failure with quality reps and tight execution.",
  },
};

const clamp = (value: number, min: number, max: number) =>
  Math.min(max, Math.max(min, value));

const formatWorkoutForLevel = (
  line: string,
  level: LevelName,
  index: number,
): WorkoutLine => {
  const profile = levelProfiles[level];

  const setPattern = /^(.*) - (\d+) sets x (\d+) reps(.*), rest (\d+)s$/;
  const roundPattern = /^(.*) - (\d+) rounds x (\d+) seconds, rest (\d+)s$/;
  const minutePattern = /^(.*) - (\d+) minutes \((.*)\)$/;

  const setMatch = line.match(setPattern);
  if (setMatch) {
    const [, name, sets, reps, repSuffix, rest] = setMatch;
    const nextSets = clamp(Number(sets) + profile.setDelta, 2, 6);
    const nextReps = clamp(Number(reps) + profile.repDelta, 5, 20);
    const nextRest = clamp(Number(rest) + profile.restDelta, 30, 180);

    return {
      name,
      plan: `${nextSets} sets x ${nextReps} reps${repSuffix}, rest ${nextRest}s · ${profile.effort}`,
      note: profile.notes[index % profile.notes.length],
    };
  }

  const roundMatch = line.match(roundPattern);
  if (roundMatch) {
    const [, name, rounds, seconds, rest] = roundMatch;
    const nextRounds = clamp(Number(rounds) + profile.roundDelta, 2, 6);
    const nextSeconds = clamp(Number(seconds) + profile.holdDelta, 20, 75);
    const nextRest = clamp(Number(rest) + profile.restDelta, 30, 120);

    return {
      name,
      plan: `${nextRounds} rounds x ${nextSeconds} seconds, rest ${nextRest}s · ${profile.effort}`,
      note: profile.notes[index % profile.notes.length],
    };
  }

  const minuteMatch = line.match(minutePattern);
  if (minuteMatch) {
    const [, name, minutes, detail] = minuteMatch;
    const nextMinutes = clamp(
      Number(minutes) +
        (level === "Advanced" ? 3 : level === "Beginner" ? -2 : 0),
      8,
      20,
    );

    return {
      name,
      plan: `${nextMinutes} minutes (${detail}) · ${profile.effort}`,
      note: profile.notes[index % profile.notes.length],
    };
  }

  const separator = line.indexOf(" - ");
  const name = separator > -1 ? line.slice(0, separator) : line;
  const plan = separator > -1 ? line.slice(separator + 3) : profile.fallback;

  return {
    name,
    plan: `${plan} · ${profile.effort}`,
    note: profile.notes[index % profile.notes.length],
  };
};

const detailedWorkout = computed<WorkoutLine[]>(() => {
  const level = state.level as LevelName;
  return todayWorkout.value.map((line, index) =>
    formatWorkoutForLevel(line, level, index),
  );
});

const normalizeCycleState = () => {
  const uniqueCompleted = Array.from(new Set(state.completedDays)).filter(
    (day) => Number.isInteger(day) && day > 0 && day <= DAYS_PER_CYCLE,
  );
  state.completedDays = uniqueCompleted;

  if (state.completedDays.length >= DAYS_PER_CYCLE) {
    state.currentDay = 1;
    state.completedDays = [];
    return;
  }

  if (state.completedDays.includes(state.currentDay)) {
    const nextDay = Array.from(
      { length: DAYS_PER_CYCLE },
      (_, index) => index + 1,
    ).find((day) => !state.completedDays.includes(day));
    state.currentDay = nextDay || 1;
  }
};

const completeDay = () => {
  if (isDoneToday.value) {
    return;
  }
  if (import.meta.client) {
    const ok = window.confirm("Mark today as completed and move to next day?");
    if (!ok) {
      return;
    }
  }
  if (!state.completedDays.includes(state.currentDay)) {
    state.completedDays.push(state.currentDay);
  }
  if (state.currentDay < DAYS_PER_CYCLE) {
    state.currentDay += 1;
    return;
  }
  state.currentDay = 1;
  state.completedDays = [];
};

onMounted(() => {
  updateStandaloneMode();
  window.addEventListener("appinstalled", updateStandaloneMode);

  const raw = localStorage.getItem(STORE_KEY);
  if (!raw) {
    return;
  }
  try {
    const saved = JSON.parse(raw) as Partial<WorkoutState>;
    if (saved.level && levels.includes(saved.level)) {
      state.level = saved.level;
    }
    const maxDay = DAYS_PER_CYCLE;
    if (
      saved.currentDay &&
      saved.currentDay > 0 &&
      saved.currentDay <= maxDay
    ) {
      state.currentDay = saved.currentDay;
    }
    if (Array.isArray(saved.completedDays)) {
      state.completedDays = saved.completedDays.filter(
        (d) => Number.isInteger(d) && d > 0 && d <= maxDay,
      );
    }
    normalizeCycleState();
  } catch {
    localStorage.removeItem(STORE_KEY);
  }
});

watch(
  () => ({ ...state }),
  () => {
    if (import.meta.client) {
      localStorage.setItem(STORE_KEY, JSON.stringify(state));
    }
  },
  { deep: true },
);

watch(hasPendingUpdate, (value) => {
  if (!value) {
    dismissUpdateBanner.value = false;
  }
});
</script>
