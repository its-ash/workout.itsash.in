<!-- eslint-disable @stylistic/quotes -->
<template>
  <main class="app-shell">
    <header class="topbar glass">
      <div class="header-actions">
        <button class="secondary" @click="showStretchingModal = true">
          🧘
        </button>
        <h1>WorkOut</h1>
        <button class="secondary right" @click="checkForUpdates">
          🔄
        </button>
      </div>
    </header>

    <section class="workspace">
      <div class="content-stack">
        <section class="day-card">
          <ul class="workouts">
            <li v-for="item in detailedWorkout" :key="item.name + item.plan"
              :class="{ clickable: item.name === runWalkName }"
              @click="item.name === runWalkName && (showRunTimerModal = true)">
              <p class="workout-name">
                {{ item.name }}
                <span v-if="item.name === runWalkName" class="timer-hint">⏱️ Tap for pace guide</span>
              </p>
              <p class="workout-plan">{{ item.plan }}</p>
            </li>
          </ul>
        </section>
      </div>
    </section>

    <div class="actions day-actions">
      <button v-if="canInstall" class="secondary" @click="installApp">
        Install App
      </button>
      <button :style="{ width: canInstall ? 'auto' : '100%' }" class="primary" :disabled="isDoneToday"
        @click="completeDay">
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

    <!-- Stretching Modal -->
    <div v-if="showStretchingModal" class="modal-overlay" @click.self="showStretchingModal = false">
      <div class="modal-content stretching-modal">
        <div class="modal-header">
          <h2>Full Body Stretching Routine</h2>
          <button class="close-btn" @click="showStretchingModal = false">
            ✕
          </button>
        </div>
        <div class="stretching-list">
          <div v-for="stretch in stretchingRoutine" :key="stretch.id" class="stretch-card">
            <div class="stretch-info">
              <h3>{{ stretch.name }}</h3>
              <p class="stretch-duration">⏱️ {{ stretch.duration }}</p>
              <p class="stretch-description">{{ stretch.description }}</p>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="primary" @click="showStretchingModal = false">
            Done
          </button>
        </div>
      </div>
    </div>

    <!-- Run/Walk Timer Modal -->
    <div v-if="showRunTimerModal" class="modal-overlay" @click.self="closeRunTimer">
      <div class="modal-content run-timer-modal">
        <div class="modal-header">
          <h2>Run/Walk Interval Timer</h2>
          <button class="close-btn" @click="closeRunTimer">
            ✕
          </button>
        </div>

        <div class="run-timer-body">
          <div class="run-timer-display">
            <p class="run-timer-clock">{{ runTimerClockLabel }}</p>
            <p class="run-timer-segment-name">{{ currentSegment.label }}</p>
            <div class="run-timer-stats">
              <div class="run-stat">
                <span class="run-stat-label">Speed</span>
                <span class="run-stat-value">{{ currentSegment.speed }}</span>
              </div>
              <div class="run-stat">
                <span class="run-stat-label">Incline</span>
                <span class="run-stat-value">{{ currentSegment.incline }}</span>
              </div>
            </div>
            <p class="run-timer-next" v-if="nextSegment">
              Next: {{ nextSegment.label }} · {{ nextSegment.speed }} · {{ nextSegment.incline }}
            </p>
          </div>

          <div class="run-timer-controls">
            <button class="primary" @click="toggleRunTimer">
              {{ isRunTimerActive ? "Pause" : (runTimerElapsed > 0 ? "Resume" : "Start") }}
            </button>
            <button class="secondary" @click="resetRunTimer">
              Reset
            </button>
          </div>

          <ul class="run-segment-list">
            <li v-for="(seg, i) in runIntervalPlan" :key="seg.label + i" :class="{ active: i === currentSegmentIndex }">
              <span class="run-segment-time">{{ seg.durationLabel }}</span>
              <span class="run-segment-label">{{ seg.label }}</span>
              <span class="run-segment-detail">{{ seg.speed }} · {{ seg.incline }}</span>
            </li>
          </ul>
        </div>

        <div class="modal-footer">
          <button class="primary" @click="closeRunTimer">
            Done
          </button>
        </div>
      </div>
    </div>
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, unref, watch } from "vue";

type SplitDay = { day: number; workout: string[] };
type SplitProgram = { id: string; title: string; days: SplitDay[] };
type WorkoutState = {
  currentDay: number;
  completedDays: number[];
};
type WorkoutLine = { name: string; plan: string; note: string };

const DAYS_PER_CYCLE = 7;

const pushPullLegsSplit: SplitProgram = {
  id: "push-pull-legs",
  title: "Push / Pull / Legs / Arms / Cardio & Stretch",
  days: [
    {
      day: 1,
      workout: [
        "Incline Dumbbell Press - 4 sets x 10 reps, rest 90s",
        "Cable Crossover - 3 sets x 12 reps, rest 75s",
        "Dumbbell Bench Press - 3 sets x 10 reps, rest 90s",
        "Standing Overhead Press - 3 sets x 8 reps, rest 120s",
        "Dumbbell Lateral Raise - 3 sets x 12 reps, rest 60s",
        "Skull Crusher - 3 sets x 10 reps, rest 75s",
        "Rope Triceps Pushdown - 3 sets x 12 reps, rest 60s",
        "Cable Crunch - 3 sets x 12 reps, rest 60s",
        "Pallof Press - 3 sets x 12 reps each side, rest 60s",
      ],
    },
    {
      day: 2,
      workout: [
        "Assisted Chin-up Machine - 4 sets x 8 reps, rest 120s",
        "Barbell Pendlay Row - 4 sets x 10 reps, rest 90s",
        "Lat Pulldown - 3 sets x 10 reps, rest 90s",
        "Barbell Shrug - 4 sets x 12 reps, rest 75s",
        "Face Pulls - 3 sets x 15 reps, rest 60s",
        "Barbell Curl - 3 sets x 8 reps, rest 75s",
        "Incline Dumbbell Curl - 3 sets x 10 reps, rest 60s",
        "Hanging Leg Raise - 3 sets x 12 reps, rest 60s",
        "Suitcase Carry - 3 sets x 45 seconds each side, rest 45s",
      ],
    },
    {
      day: 3,
      workout: [
        "Glute Bridge - 4 sets x 12 reps, rest 90s",
        "Walking Lunge - 3 sets x 10 reps each leg, rest 90s",
        "Leg Press - 4 sets x 12 reps, rest 90s",
        "Romanian Deadlift - 3 sets x 12 reps, rest 90s",
        "Leg Extension - 3 sets x 15 reps, rest 60s",
        "Leg Curl - 3 sets x 15 reps, rest 60s",
        "Standing Calf Raise - 4 sets x 15 reps, rest 60s",
        "Cable Crunch - 3 sets x 15 reps, rest 60s",
        "Dragon Flag Progression - 3 sets x 6 reps, rest 90s",
      ],
    },
    {
      day: 4,
      workout: [
        "Dumbbell Incline Press - 4 sets x 10 reps, rest 90s",
        "Machine Chest Press - 3 sets x 12 reps, rest 75s",
        "Dumbbell Shoulder Press - 3 sets x 12 reps, rest 75s",
        "Cable Lateral Raise - 3 sets x 15 reps, rest 60s",
        "Reverse Pec Deck - 3 sets x 15 reps, rest 60s",
        "Overhead Cable Triceps Extension - 3 sets x 12 reps, rest 60s",
        "Dip Machine - 3 sets x 10 reps, rest 75s",
        "Reverse Grip Cable Pushdown - 3 sets x 15 reps, rest 60s",
      ],
    },
    {
      day: 5,
      workout: [
        "Lat Pulldown - 4 sets x 10 reps, rest 90s",
        "Sealed Chest Supported Row - 4 sets x 12 reps, rest 75s",
        "Face Pulls - 3 sets x 15 reps, rest 60s",
        "Machine Curl - 3 sets x 12 reps, rest 75s",
        "Reverse Cable Curl - 3 sets x 12 reps, rest 60s",
        "Dumbbell Hammer Curl - 3 sets x 12 reps, rest 60s",
        "Hanging Leg Raise - 3 sets x 12 reps, rest 60s",
        "Cable Crunch - 3 sets x 15 reps, rest 60s",
      ],
    },
    {
      day: 6,
      workout: [
        "Close Grip Bench Press - 4 sets x 8 reps, rest 90s",
        "Overhead Dumbbell Extension - 3 sets x 12 reps, rest 60s",
        "Reverse Grip Cable Pushdown - 3 sets x 15 reps, rest 60s",
        "Barbell Curl - 4 sets x 10 reps, rest 75s",
        "Incline Dumbbell Curl - 3 sets x 10 reps, rest 60s",
        "Cable Rope Hammer Curl - 3 sets x 12 reps, rest 60s",
        "Concentration Curl - 3 sets x 12 reps each side, rest 60s",
        "Hanging Leg Raise - 3 sets x 12 reps, rest 60s",
      ],
    },
    {
      day: 7,
      workout: [
        "Run/Walk Interval Protocol - 10 minutes, tap timer for pace guide",
        "Stationary Bike - 20 minutes, moderate intensity",
        "Full Body Stretching Routine - 10 minutes",
        "Foam Rolling - 5 minutes",
      ],
    },
  ],
};

const STORE_KEY = "workout-pwa-v1";

const state = reactive<WorkoutState>({
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
const manualUpdateCheck = ref(false);
const showStretchingModal = ref(false);
const runWalkName = "Run/Walk Interval Protocol";

type RunSegment = {
  label: string;
  speed: string;
  incline: string;
  seconds: number;
  durationLabel: string;
};

const runIntervalPlan: RunSegment[] = [
  { label: "Warm-Up Walk", speed: "3.5 mph", incline: "2%", seconds: 120, durationLabel: "0:00-2:00" },
  { label: "Run Interval 1", speed: "6.0 mph", incline: "1%", seconds: 60, durationLabel: "2:00-3:00" },
  { label: "Recovery Walk", speed: "3.5 mph", incline: "4%", seconds: 90, durationLabel: "3:00-4:30" },
  { label: "Run Interval 2", speed: "6.5 mph", incline: "1%", seconds: 60, durationLabel: "4:30-5:30" },
  { label: "Recovery Walk", speed: "3.5 mph", incline: "4%", seconds: 90, durationLabel: "5:30-7:00" },
  { label: "Run Interval 3", speed: "7.0 mph", incline: "1%", seconds: 60, durationLabel: "7:00-8:00" },
  { label: "Cool-Down Walk", speed: "3.0 mph", incline: "2%", seconds: 120, durationLabel: "8:00-10:00" },
];

const runIntervalTotalSeconds = runIntervalPlan.reduce(
  (sum, seg) => sum + seg.seconds,
  0,
);

const showRunTimerModal = ref(false);
const isRunTimerActive = ref(false);
const runTimerElapsed = ref(0);
let runTimerHandle: ReturnType<typeof setInterval> | null = null;

const currentSegmentIndex = computed(() => {
  let acc = 0;
  for (let i = 0; i < runIntervalPlan.length; i += 1) {
    acc += runIntervalPlan[i].seconds;
    if (runTimerElapsed.value < acc) {
      return i;
    }
  }
  return runIntervalPlan.length - 1;
});

const currentSegment = computed(() => runIntervalPlan[currentSegmentIndex.value]);
const nextSegment = computed(
  () => runIntervalPlan[currentSegmentIndex.value + 1] || null,
);

const runTimerClockLabel = computed(() => {
  const remaining = Math.max(runIntervalTotalSeconds - runTimerElapsed.value, 0);
  const mins = Math.floor(remaining / 60);
  const secs = remaining % 60;
  return `${mins}:${String(secs).padStart(2, "0")}`;
});

const stopRunTimerInterval = () => {
  if (runTimerHandle !== null) {
    clearInterval(runTimerHandle);
    runTimerHandle = null;
  }
};

const toggleRunTimer = () => {
  if (isRunTimerActive.value) {
    isRunTimerActive.value = false;
    stopRunTimerInterval();
    return;
  }
  if (runTimerElapsed.value >= runIntervalTotalSeconds) {
    runTimerElapsed.value = 0;
  }
  isRunTimerActive.value = true;
  runTimerHandle = setInterval(() => {
    if (runTimerElapsed.value >= runIntervalTotalSeconds) {
      isRunTimerActive.value = false;
      stopRunTimerInterval();
      return;
    }
    runTimerElapsed.value += 1;
  }, 1000);
};

const resetRunTimer = () => {
  isRunTimerActive.value = false;
  stopRunTimerInterval();
  runTimerElapsed.value = 0;
};

const closeRunTimer = () => {
  showRunTimerModal.value = false;
  isRunTimerActive.value = false;
  stopRunTimerInterval();
};

const stretchingRoutine = [
  {
    id: "neck-rolls",
    name: "Neck Rolls",
    duration: "30 seconds",
    description: "Gently rotate your head in circles",
    instruction:
      "Slowly roll your head clockwise, then counterclockwise. Keep shoulders relaxed.",
  },
  {
    id: "neck-side-stretch",
    name: "Neck Side Stretch",
    duration: "30 seconds each side",
    description: "Stretch neck and shoulder muscles",
    instruction:
      "Tilt head toward shoulder. Use gentle hand pressure. Breathe deeply.",
  },
  {
    id: "shoulder-rolls",
    name: "Shoulder Rolls",
    duration: "30 seconds",
    description: "Roll shoulders backward to release tension",
    instruction:
      "Lift shoulders to ears, roll back and down. Repeat 10 times each direction.",
  },
  {
    id: "shoulder-blade-squeeze",
    name: "Shoulder Blade Squeeze",
    duration: "30 seconds",
    description: "Strengthen and stretch upper back",
    instruction:
      "Squeeze shoulder blades together, hold 2 seconds. Release and relax.",
  },
  {
    id: "chest-opener",
    name: "Chest Opener",
    duration: "45 seconds each side",
    description: "Open up your chest and shoulders",
    instruction:
      "Clasp hands behind back, straighten arms, lift chest. Hold and breathe deeply.",
  },
  {
    id: "tricep-stretch",
    name: "Tricep Stretch",
    duration: "45 seconds each arm",
    description: "Release tension in back of arms",
    instruction:
      "Reach one arm overhead, bend elbow. Gently press elbow back with other hand.",
  },
  {
    id: "lat-stretch",
    name: "Lat Stretch",
    duration: "45 seconds each side",
    description: "Stretch sides and latissimus dorsi",
    instruction:
      "Reach arm overhead and lean to opposite side. Feel stretch along side body.",
  },
  {
    id: "wrist-forearm",
    name: "Wrist & Forearm Stretch",
    duration: "30 seconds each arm",
    description: "Release wrist and forearm tightness",
    instruction:
      "Extend arm, press palm down with other hand. Reverse for back of forearm.",
  },
  {
    id: "cat-cow",
    name: "Cat-Cow Stretch",
    duration: "1 minute",
    description: "Mobilize your entire spine",
    instruction:
      "On hands and knees: arch back (cow), then round spine (cat). Flow smoothly.",
  },
  {
    id: "child-pose",
    name: "Child's Pose",
    duration: "1 minute",
    description: "Full body relaxation and back stretch",
    instruction:
      "Kneel, sit hips back to heels, extend arms forward. Rest forehead down.",
  },
  {
    id: "cobra-stretch",
    name: "Cobra Stretch",
    duration: "45 seconds",
    description: "Open chest and stretch front of body",
    instruction:
      "Lie face down, push chest up with hands, keep hips on ground. Arch gently.",
  },
  {
    id: "forward-fold",
    name: "Forward Fold",
    duration: "1 minute",
    description: "Stretch hamstrings and lower back",
    instruction:
      "Bend forward from hips. Let arms hang. Relax and let gravity do the work.",
  },
  {
    id: "quad-stretch",
    name: "Quadriceps Stretch",
    duration: "45 seconds each leg",
    description: "Release tension in front thighs",
    instruction:
      "Standing, pull one foot to glutes. Keep knees together. Hold each leg.",
  },
  {
    id: "hamstring",
    name: "Hamstring Stretch",
    duration: "1 minute each leg",
    description: "Loosen tight hamstrings",
    instruction:
      "Extend one leg, hinge at hips. Keep back straight. Feel the stretch behind thigh.",
  },
  {
    id: "glute-stretch",
    name: "Glute Stretch",
    duration: "45 seconds each side",
    description: "Release glute and hip tension",
    instruction:
      "Lying down, pull one knee to opposite shoulder. Hold and relax deeply.",
  },
  {
    id: "hip-opener",
    name: "Hip Opener",
    duration: "1 minute each side",
    description: "Release hip flexors and glutes",
    instruction:
      "Pigeon pose: one leg extended back, other bent forward. Sink hips down gently.",
  },
  {
    id: "butterfly-stretch",
    name: "Butterfly Stretch",
    duration: "1 minute",
    description: "Open inner thighs and hips",
    instruction:
      "Sit, soles of feet together, knees out. Lean forward gently. Keep back straight.",
  },
  {
    id: "spinal-twist",
    name: "Spinal Twist",
    duration: "45 seconds each side",
    description: "Decompress spine and improve mobility",
    instruction:
      "Seated or lying, cross one leg over, gently twist to opposite side.",
  },
  {
    id: "calf-stretch",
    name: "Calf Stretch",
    duration: "45 seconds each leg",
    description: "Release tight calves",
    instruction:
      "Step back, heel down, lean forward. Keep leg straight. Feel stretch in calf.",
  },
  {
    id: "lower-back",
    name: "Lower Back Stretch",
    duration: "1 minute",
    description: "Relieve lower back tension",
    instruction:
      "Lying on back, pull both knees to chest. Hold and breathe deeply.",
  },
];

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

const hasPendingUpdate = computed(
  () => Boolean(unref(pwa?.needRefresh)) || manualUpdateCheck.value,
);

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

const checkForUpdates = async () => {
  if (!import.meta.client) {
    return;
  }
  try {
    const registration = await navigator.serviceWorker.getRegistration();
    if (registration) {
      await registration.update();
      manualUpdateCheck.value = true;
    }
  } catch (error) {
    console.log("Update check error:", error);
  }
};

const advancedProfile = {
  effort: "RIR 0-1",
  notes: [
    "Push top sets close to failure while preserving mechanics.",
    "Use full intent on every rep and track performance precisely.",
    "Shorten rest only if output and technique stay high.",
  ],
};

const formatWorkout = (line: string, index: number): WorkoutLine => {
  const separator = line.indexOf(" - ");
  const name = separator > -1 ? line.slice(0, separator) : line;
  const plan = separator > -1 ? line.slice(separator + 3) : "";

  return {
    name,
    plan: `${plan} · ${advancedProfile.effort}`,
    note: advancedProfile.notes[index % advancedProfile.notes.length],
  };
};

const detailedWorkout = computed<WorkoutLine[]>(() => {
  return todayWorkout.value.map((line, index) => formatWorkout(line, index));
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

  if (import.meta.client && navigator.serviceWorker) {
    navigator.serviceWorker.addEventListener("controllerchange", () => {
      manualUpdateCheck.value = true;
    });
  }

  const raw = localStorage.getItem(STORE_KEY);
  if (!raw) {
    return;
  }
  try {
    const saved = JSON.parse(raw) as Partial<WorkoutState>;
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

onUnmounted(() => {
  stopRunTimerInterval();
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
    manualUpdateCheck.value = false;
  }
});
</script>
