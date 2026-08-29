<!-- eslint-disable @stylistic/quotes -->
<template>
  <main class="app-shell">
    <header class="topbar glass">
      <div class="header-actions">
        <button
          class="secondary"
          aria-label="Open stretching routine"
          title="Stretching routine"
          @click="showStretchingModal = true"
        >
          🧘
        </button>
        <button
          class="secondary"
          aria-label="Open treadmill setup"
          title="Treadmill setup"
          @click="showTreadmillModal = true"
        >
          🏃
        </button>
        <h1>WorkOut</h1>
      </div>
    </header>

    <section class="workspace">
      <div class="content-stack">
        <section class="day-card">
          <div class="session-selector">
            <button
              v-for="t in sessionTypes"
              :key="t.id"
              class="session-type-btn"
              :class="{ active: state.sessionType === t.id }"
              @click="selectSessionType(t.id)"
            >
              {{ t.icon }} {{ t.label }}
            </button>
          </div>
          <div class="day-progress">
            <div class="day-progress-head">
              <button
                class="day-nav-btn"
                aria-label="Shuffle workout"
                title="Shuffle workout"
                @click="shuffleWorkout"
              >
                🎲
              </button>
              <p class="day-progress-title">
                {{ dayTitle }}
              </p>
              <button
                class="day-nav-btn"
                aria-label="Next variation"
                title="Next variation"
                @click="nextVariation"
              >
                &rarr;
              </button>
            </div>
          </div>
          <ul class="workouts">
            <li
              v-for="item in detailedWorkout"
              :key="item.name + item.plan"
              :class="{ clickable: item.name === runWalkName }"
              @click="item.name === runWalkName && (showRunTimerModal = true)"
            >
              <div class="workout-row">
                <div class="workout-text">
                  <p class="workout-name">
                    {{ item.name }}
                    <span
                      v-if="item.name === runWalkName"
                      class="timer-hint"
                    >⏱️ Tap for pace guide</span>
                  </p>
                  <p class="workout-plan">
                    {{ item.plan }}
                  </p>
                </div>
                <button
                  v-if="item.gif"
                  class="secondary workout-view-btn"
                  aria-label="View exercise gif"
                  title="View exercise"
                  @click.stop="openGifModal(item)"
                >
                  ▶
                </button>
              </div>
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
      <button
        class="secondary"
        :disabled="isSessionActive"
        @click="startSession"
      >
        {{ isSessionActive ? sessionClockLabel : "Start" }}
      </button>
      <button
        v-if="isSessionActive"
        class="primary"
        @click="requestStopSession"
      >
        Stop
      </button>
    </div>

    <!-- Stretching Modal -->
    <div
      v-if="showStretchingModal"
      class="modal-overlay"
      @click.self="showStretchingModal = false"
    >
      <div class="modal-content stretching-modal">
        <div class="modal-header">
          <h2>Full Body Stretching Routine</h2>
          <button
            class="close-btn"
            @click="showStretchingModal = false"
          >
            ✕
          </button>
        </div>
        <div class="stretching-list">
          <div
            v-for="stretch in stretchingRoutine"
            :key="stretch.id"
            class="stretch-card"
          >
            <div
              v-if="stretch.gif"
              class="stretch-gif-wrap"
            >
              <div
                v-if="!loadedGifs.has(stretch.id)"
                class="gif-loader"
                aria-label="Loading gif"
              >
                <span class="gif-spinner" />
              </div>
              <img
                :src="stretch.gif"
                :alt="stretch.name"
                class="stretch-gif"
                :class="{ hidden: !loadedGifs.has(stretch.id) }"
                loading="lazy"
                @load="onGifLoad(stretch.id)"
                @error="onGifLoad(stretch.id)"
              >
            </div>
            <div class="stretch-info">
              <h3>{{ stretch.name }}</h3>
              <p class="stretch-duration">
                ⏱️ {{ stretch.duration }}
              </p>
              <p class="stretch-description">
                {{ stretch.description }}
              </p>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button
            class="primary"
            @click="showStretchingModal = false"
          >
            Done
          </button>
        </div>
      </div>
    </div>

    <!-- Exercise Gif Modal -->
    <div
      v-if="showGifModal"
      class="modal-overlay"
      @click.self="closeGifModal"
    >
      <div class="modal-content gif-modal">
        <div class="modal-header">
          <h2>{{ activeGif?.name }}</h2>
          <button
            class="close-btn"
            @click="closeGifModal"
          >
            ✕
          </button>
        </div>
        <div class="gif-body">
          <div
            v-if="activeGif?.gif && !activeGifLoaded"
            class="gif-loader gif-loader-lg"
            aria-label="Loading gif"
          >
            <span class="gif-spinner" />
          </div>
          <img
            v-if="activeGif?.gif"
            :src="activeGif.gif"
            :alt="activeGif.name"
            class="gif-image"
            :class="{ hidden: !activeGifLoaded }"
            @load="activeGifLoaded = true"
            @error="activeGifLoaded = true"
          >
          <p
            v-if="activeGif?.plan"
            class="gif-plan"
          >
            {{ activeGif.plan }}
          </p>
        </div>
        <div class="modal-footer">
          <button
            class="primary"
            @click="closeGifModal"
          >
            Done
          </button>
        </div>
      </div>
    </div>

    <!-- Session Timer Modal -->
    <div
      v-if="showSessionTimerModal"
      class="modal-overlay"
      @click.self="cancelStopSession"
    >
      <div class="modal-content session-timer-modal">
        <div class="modal-header">
          <h2>Stop Workout Session?</h2>
          <button
            class="close-btn"
            @click="cancelStopSession"
          >
            ✕
          </button>
        </div>
        <div class="session-timer-body">
          <p class="session-timer-summary">
            Session duration: <strong>{{ sessionClockLabel }}</strong>
          </p>
          <p class="session-timer-text">
            Stopping will export today's workout to Google Calendar.
          </p>
        </div>
        <div class="modal-footer">
          <button
            class="secondary"
            @click="cancelStopSession"
          >
            Cancel
          </button>
          <button
            class="primary"
            @click="confirmStopSession"
          >
            Stop & Export
          </button>
        </div>
      </div>
    </div>

    <!-- Run/Walk Timer Modal -->
    <div
      v-if="showRunTimerModal"
      class="modal-overlay"
      @click.self="closeRunTimer"
    >
      <div class="modal-content run-timer-modal">
        <div class="modal-header">
          <h2>Run/Walk Interval Timer</h2>
          <button
            class="close-btn"
            @click="closeRunTimer"
          >
            ✕
          </button>
        </div>

        <div class="run-timer-body">
          <div class="run-timer-display">
            <p class="run-timer-clock">
              {{ runTimerClockLabel }}
            </p>
            <p class="run-timer-segment-name">
              {{ currentSegment.label }}
            </p>
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
            <p
              v-if="nextSegment"
              class="run-timer-next"
            >
              Next: {{ nextSegment.label }} · {{ nextSegment.speed }} · {{ nextSegment.incline }}
            </p>
          </div>

          <div class="run-timer-controls">
            <button
              class="primary"
              @click="toggleRunTimer"
            >
              {{ isRunTimerActive ? "Pause" : (runTimerElapsed > 0 ? "Resume" : "Start") }}
            </button>
            <button
              class="secondary"
              @click="resetRunTimer"
            >
              Reset
            </button>
          </div>

          <ul class="run-segment-list">
            <li
              v-for="(seg, i) in runIntervalPlan"
              :key="seg.label + i"
              :class="{ active: i === currentSegmentIndex }"
            >
              <span class="run-segment-time">{{ seg.durationLabel }}</span>
              <span class="run-segment-label">{{ seg.label }}</span>
              <span class="run-segment-detail">{{ seg.speed }} · {{ seg.incline }}</span>
            </li>
          </ul>
        </div>

        <div class="modal-footer">
          <button
            class="primary"
            @click="closeRunTimer"
          >
            Done
          </button>
        </div>
      </div>
    </div>
    <!-- Treadmill Setup Modal -->
    <div
      v-if="showTreadmillModal"
      class="modal-overlay"
      @click.self="closeTreadmill"
    >
      <div class="modal-content treadmill-modal run-timer-modal">
        <div class="modal-header">
          <h2>Treadmill Setup</h2>
          <button
            class="close-btn"
            @click="closeTreadmill"
          >
            ✕
          </button>
        </div>

        <div class="treadmill-fixed">
          <div class="run-timer-display">
            <p class="run-timer-clock">
              {{ treadmillClockLabel }}
            </p>
            <p class="run-timer-segment-name">
              {{ currentTreadmillSegment.label }}
            </p>
            <div class="run-timer-stats">
              <div class="run-stat">
                <span class="run-stat-label">Speed</span>
                <span class="run-stat-value run-stat-value-lg">{{ currentTreadmillSegment.speed }}</span>
              </div>
              <div class="run-stat">
                <span class="run-stat-label">Incline</span>
                <span class="run-stat-value run-stat-value-lg">{{ currentTreadmillSegment.incline }}</span>
              </div>
            </div>
            <div class="treadmill-upcoming">
              <div
                v-if="nextTreadmillSegment"
                class="treadmill-next-card"
              >
                <span class="treadmill-next-label">Next</span>
                <span class="treadmill-next-name">{{ nextTreadmillSegment.label }}</span>
                <span class="treadmill-next-detail">{{ nextTreadmillSegment.speed }} · {{ nextTreadmillSegment.incline }}</span>
              </div>
              <div
                v-if="nextNextTreadmillSegment"
                class="treadmill-next-card treadmill-next-card-2"
              >
                <span class="treadmill-next-label">Then</span>
                <span class="treadmill-next-name">{{ nextNextTreadmillSegment.label }}</span>
                <span class="treadmill-next-time">{{ nextNextTreadmillSegment.durationLabel }}</span>
              </div>
            </div>
          </div>

          <div class="run-timer-controls">
            <button
              class="primary"
              @click="toggleTreadmill"
            >
              {{ isTreadmillActive ? "Pause" : (treadmillElapsed > 0 ? "Resume" : "Start") }}
            </button>
            <button
              class="secondary"
              @click="resetTreadmill"
            >
              Reset
            </button>
          </div>
        </div>

        <div class="treadmill-scroll">
          <ul class="run-segment-list">
            <li
              v-for="(seg, i) in treadmillPlan"
              :key="seg.label + i"
              :class="{ active: i === currentTreadmillSegmentIndex }"
            >
              <span class="run-segment-time">{{ seg.durationLabel }}</span>
              <span class="run-segment-label">{{ seg.label }}</span>
              <span class="run-segment-detail">{{ seg.speed }} · {{ seg.incline }}</span>
            </li>
          </ul>
        </div>

        <div class="modal-footer">
          <button
            class="primary"
            @click="closeTreadmill"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, unref } from 'vue'
import type { SessionType, WorkoutSession } from './types'
import { workoutSessions } from './workout-sessions'

type WorkoutState = {
  sessionType: SessionType
  sessionId: string
  sessionHistory: string[]
}
type WorkoutLine = { name: string, plan: string, gif?: string }

const sessionTypes: { id: SessionType, label: string, icon: string }[] = [
  { id: 'push', label: 'Push', icon: '💪' },
  { id: 'pull', label: 'Pull', icon: '🏋️' },
  { id: 'legs', label: 'Legs', icon: '🦵' },
]

type ExerciseRecord = {
  name: string
  gif_url: string
}

const exerciseDb = ref<ExerciseRecord[]>([])

const normalizeName = (s: string) =>
  s.toLowerCase().replace(/[^a-z0-9\s]/g, '').replace(/\s+/g, ' ').trim()

const findGifForWorkout = (workoutName: string): string | undefined => {
  const norm = normalizeName(workoutName)
  const words = norm.split(' ').filter(Boolean)
  if (!words.length) {
    return undefined
  }
  const ranked = exerciseDb.value
    .map((ex) => {
      const exNorm = normalizeName(ex.name)
      let score = 0
      for (const w of words) {
        if (exNorm.includes(w)) {
          score += w.length > 3 ? 2 : 1
        }
      }
      return { ex, score }
    })
    .filter(r => r.score > 0)
    .sort((a, b) => b.score - a.score)
  return ranked.length ? `/data/${ranked[0]!.ex.gif_url}` : undefined
}

const STORE_KEY = 'workout-pwa-v1'

const sessionsByType = (type: SessionType): WorkoutSession[] =>
  workoutSessions.filter(s => s.type === type)

const randomSessionId = (type: SessionType, exclude?: string): string => {
  const pool = sessionsByType(type).filter(s => s.id !== exclude)
  if (!pool.length) {
    return sessionsByType(type)[0]!.id
  }
  return pool[Math.floor(Math.random() * pool.length)]!.id
}

const state = reactive<WorkoutState>({
  sessionType: 'push',
  sessionId: workoutSessions[0]!.id,
  sessionHistory: [],
})

const currentSession = computed<WorkoutSession>(
  () => workoutSessions.find(s => s.id === state.sessionId) ?? workoutSessions[0]!,
)
const todayWorkout = computed(() => currentSession.value.workout)
const dayTitle = computed(() => currentSession.value.title)

const selectSessionType = (type: SessionType) => {
  state.sessionType = type
  state.sessionId = randomSessionId(type)
  state.sessionHistory = [state.sessionId]
}

const shuffleWorkout = () => {
  state.sessionId = randomSessionId(state.sessionType, state.sessionId)
  state.sessionHistory.push(state.sessionId)
}

const nextVariation = () => {
  const pool = sessionsByType(state.sessionType)
  const idx = pool.findIndex(s => s.id === state.sessionId)
  const next = pool[(idx + 1) % pool.length] ?? pool[0]!
  state.sessionId = next.id
  state.sessionHistory.push(next.id)
}
const pwa = usePWA() as unknown as {
  showInstallPrompt?: unknown
  isInstalled?: unknown
  isPWAInstalled?: unknown
  install?: () => Promise<unknown>
}
const standaloneMode = ref(false)
const showStretchingModal = ref(false)
const runWalkName = 'Run/Walk Interval Protocol'

type RunSegment = {
  label: string
  speed: string
  incline: string
  seconds: number
  durationLabel: string
}

const runIntervalPlan: RunSegment[] = [
  { label: 'Warm-Up Walk', speed: '3.5 mph', incline: '2%', seconds: 120, durationLabel: '0:00-2:00' },
  { label: 'Run Interval 1', speed: '6.0 mph', incline: '1%', seconds: 60, durationLabel: '2:00-3:00' },
  { label: 'Recovery Walk', speed: '3.5 mph', incline: '4%', seconds: 90, durationLabel: '3:00-4:30' },
  { label: 'Run Interval 2', speed: '6.5 mph', incline: '1%', seconds: 60, durationLabel: '4:30-5:30' },
  { label: 'Recovery Walk', speed: '3.5 mph', incline: '4%', seconds: 90, durationLabel: '5:30-7:00' },
  { label: 'Run Interval 3', speed: '7.0 mph', incline: '1%', seconds: 60, durationLabel: '7:00-8:00' },
  { label: 'Cool-Down Walk', speed: '3.0 mph', incline: '2%', seconds: 120, durationLabel: '8:00-10:00' },
]

const runIntervalTotalSeconds = runIntervalPlan.reduce(
  (sum, seg) => sum + seg.seconds,
  0,
)

const showRunTimerModal = ref(false)
const isRunTimerActive = ref(false)
const runTimerElapsed = ref(0)
let runTimerHandle: ReturnType<typeof setInterval> | null = null

const isSessionActive = ref(false)
const sessionElapsed = ref(0)
let sessionHandle: ReturnType<typeof setInterval> | null = null
const showSessionTimerModal = ref(false)

const currentSegmentIndex = computed(() => {
  let acc = 0
  for (let i = 0; i < runIntervalPlan.length; i += 1) {
    acc += runIntervalPlan[i]!.seconds
    if (runTimerElapsed.value < acc) {
      return i
    }
  }
  return runIntervalPlan.length - 1
})

const currentSegment = computed(() => runIntervalPlan[currentSegmentIndex.value]!)
const nextSegment = computed(
  () => runIntervalPlan[currentSegmentIndex.value + 1] || null,
)

const runTimerClockLabel = computed(() => {
  const remaining = Math.max(runIntervalTotalSeconds - runTimerElapsed.value, 0)
  const mins = Math.floor(remaining / 60)
  const secs = remaining % 60
  return `${mins}:${String(secs).padStart(2, '0')}`
})

const stopRunTimerInterval = () => {
  if (runTimerHandle !== null) {
    clearInterval(runTimerHandle)
    runTimerHandle = null
  }
}

const toggleRunTimer = () => {
  if (isRunTimerActive.value) {
    isRunTimerActive.value = false
    stopRunTimerInterval()
    return
  }
  if (runTimerElapsed.value >= runIntervalTotalSeconds) {
    runTimerElapsed.value = 0
  }
  isRunTimerActive.value = true
  runTimerHandle = setInterval(() => {
    if (runTimerElapsed.value >= runIntervalTotalSeconds) {
      isRunTimerActive.value = false
      stopRunTimerInterval()
      return
    }
    runTimerElapsed.value += 1
  }, 1000)
}

const resetRunTimer = () => {
  isRunTimerActive.value = false
  stopRunTimerInterval()
  runTimerElapsed.value = 0
}

const closeRunTimer = () => {
  showRunTimerModal.value = false
  isRunTimerActive.value = false
  stopRunTimerInterval()
}

const sessionClockLabel = computed(() => {
  const secs = sessionElapsed.value
  const h = Math.floor(secs / 3600)
  const m = Math.floor((secs % 3600) / 60)
  const s = secs % 60
  const pad = (n: number) => String(n).padStart(2, '0')
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`
})

const stopSessionInterval = () => {
  if (sessionHandle !== null) {
    clearInterval(sessionHandle)
    sessionHandle = null
  }
}

const startSession = () => {
  if (isSessionActive.value) {
    return
  }
  isSessionActive.value = true
  sessionElapsed.value = 0
  sessionHandle = setInterval(() => {
    sessionElapsed.value += 1
  }, 1000)
}

const requestStopSession = () => {
  if (!isSessionActive.value) {
    return
  }
  stopSessionInterval()
  isSessionActive.value = false
  showSessionTimerModal.value = true
}

const cancelStopSession = () => {
  showSessionTimerModal.value = false
}

const confirmStopSession = () => {
  showSessionTimerModal.value = false
  if (!import.meta.client) {
    return
  }
  const startMs = Date.now() - sessionElapsed.value * 1000
  const endMs = Date.now()
  const title = `Workout · ${dayTitle.value}`
  const details = detailedWorkout.value
    .map(w => `• ${w.name} — ${w.plan}`)
    .join('\n')
  const fmt = (ts: number) => {
    const d = new Date(ts)
    return d.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z'
  }
  const dates = `${fmt(startMs)}/${fmt(endMs)}`
  const location = 'Gym'
  const url = `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(title)}&dates=${dates}&details=${encodeURIComponent(details)}&location=${encodeURIComponent(location)}`
  window.open(url, '_blank', 'noopener,noreferrer')
  sessionElapsed.value = 0
}

const stretchingRoutine = [
  {
    id: 'neck-rolls',
    name: 'Neck Rolls',
    duration: '30 seconds',
    description: 'Gently rotate your head in circles',
    instruction:
      'Slowly roll your head clockwise, then counterclockwise. Keep shoulders relaxed.',
    gif: '/data/videos/1403-x2chWLO.gif',
  },
  {
    id: 'neck-side-stretch',
    name: 'Neck Side Stretch',
    duration: '30 seconds each side',
    description: 'Stretch neck and shoulder muscles',
    instruction:
      'Tilt head toward shoulder. Use gentle hand pressure. Breathe deeply.',
    gif: '/data/videos/0716-oQRJYkC.gif',
  },
  {
    id: 'shoulder-rolls',
    name: 'Shoulder Rolls',
    duration: '30 seconds',
    description: 'Roll shoulders backward to release tension',
    instruction:
      'Lift shoulders to ears, roll back and down. Repeat 10 times each direction.',
    gif: '/data/videos/1259-QoHIhPl.gif',
  },
  {
    id: 'shoulder-blade-squeeze',
    name: 'Shoulder Blade Squeeze',
    duration: '30 seconds',
    description: 'Strengthen and stretch upper back',
    instruction:
      'Squeeze shoulder blades together, hold 2 seconds. Release and relax.',
    gif: '/data/videos/1271-Uto7l43.gif',
  },
  {
    id: 'chest-opener',
    name: 'Chest Opener',
    duration: '45 seconds each side',
    description: 'Open up your chest and shoulders',
    instruction:
      'Clasp hands behind back, straighten arms, lift chest. Hold and breathe deeply.',
    gif: '/data/videos/1167-3uj0Ozg.gif',
  },
  {
    id: 'tricep-stretch',
    name: 'Tricep Stretch',
    duration: '45 seconds each arm',
    description: 'Release tension in back of arms',
    instruction:
      'Reach one arm overhead, bend elbow. Gently press elbow back with other hand.',
    gif: '/data/videos/0643-Z5YStHW.gif',
  },
  {
    id: 'lat-stretch',
    name: 'Lat Stretch',
    duration: '45 seconds each side',
    description: 'Stretch sides and latissimus dorsi',
    instruction:
      'Reach arm overhead and lean to opposite side. Feel stretch along side body.',
    gif: '/data/videos/1346-f38OEuO.gif',
  },
  {
    id: 'wrist-forearm',
    name: 'Wrist & Forearm Stretch',
    duration: '30 seconds each arm',
    description: 'Release wrist and forearm tightness',
    instruction:
      'Extend arm, press palm down with other hand. Reverse for back of forearm.',
    gif: '/data/videos/0721-UtmIqcI.gif',
  },
  {
    id: 'cat-cow',
    name: 'Cat-Cow Stretch',
    duration: '1 minute',
    description: 'Mobilize your entire spine',
    instruction:
      'On hands and knees: arch back (cow), then round spine (cat). Flow smoothly.',
    gif: '/data/videos/2208-isofgzg.gif',
  },
  {
    id: 'child-pose',
    name: 'Child\'s Pose',
    duration: '1 minute',
    description: 'Full body relaxation and back stretch',
    instruction:
      'Kneel, sit hips back to heels, extend arms forward. Rest forehead down.',
    gif: '/data/videos/2204-XeMvLgE.gif',
  },
  {
    id: 'cobra-stretch',
    name: 'Cobra Stretch',
    duration: '45 seconds',
    description: 'Open chest and stretch front of body',
    instruction:
      'Lie face down, push chest up with hands, keep hips on ground. Arch gently.',
    gif: '/data/videos/3662-XPUDTt7.gif',
  },
  {
    id: 'forward-fold',
    name: 'Forward Fold',
    duration: '1 minute',
    description: 'Stretch hamstrings and lower back',
    instruction:
      'Bend forward from hips. Let arms hang. Relax and let gravity do the work.',
    gif: '/data/videos/1599-xTjr103.gif',
  },
  {
    id: 'quad-stretch',
    name: 'Quadriceps Stretch',
    duration: '45 seconds each leg',
    description: 'Release tension in front thighs',
    instruction:
      'Standing, pull one foot to glutes. Keep knees together. Hold each leg.',
    gif: '/data/videos/1713-YUYAMEj.gif',
  },
  {
    id: 'hamstring',
    name: 'Hamstring Stretch',
    duration: '1 minute each leg',
    description: 'Loosen tight hamstrings',
    instruction:
      'Extend one leg, hinge at hips. Keep back straight. Feel the stretch behind thigh.',
    gif: '/data/videos/1511-99rWm7w.gif',
  },
  {
    id: 'glute-stretch',
    name: 'Glute Stretch',
    duration: '45 seconds each side',
    description: 'Release glute and hip tension',
    instruction:
      'Lying down, pull one knee to opposite shoulder. Hold and relax deeply.',
    gif: '/data/videos/1424-DeDThfG.gif',
  },
  {
    id: 'hip-opener',
    name: 'Hip Opener',
    duration: '1 minute each side',
    description: 'Release hip flexors and glutes',
    instruction:
      'Pigeon pose: one leg extended back, other bent forward. Sink hips down gently.',
    gif: '/data/videos/1559-2LQkNPW.gif',
  },
  {
    id: 'butterfly-stretch',
    name: 'Butterfly Stretch',
    duration: '1 minute',
    description: 'Open inner thighs and hips',
    instruction:
      'Sit, soles of feet together, knees out. Lean forward gently. Keep back straight.',
    gif: '/data/videos/1494-bWlZvXh.gif',
  },
  {
    id: 'spinal-twist',
    name: 'Spinal Twist',
    duration: '45 seconds each side',
    description: 'Decompress spine and improve mobility',
    instruction:
      'Seated or lying, cross one leg over, gently twist to opposite side.',
    gif: '/data/videos/1363-JbC2iaV.gif',
  },
  {
    id: 'calf-stretch',
    name: 'Calf Stretch',
    duration: '45 seconds each leg',
    description: 'Release tight calves',
    instruction:
      'Step back, heel down, lean forward. Keep leg straight. Feel stretch in calf.',
    gif: '/data/videos/1398-qOKcgVP.gif',
  },
  {
    id: 'lower-back',
    name: 'Lower Back Stretch',
    duration: '1 minute',
    description: 'Relieve lower back tension',
    instruction:
      'Lying on back, pull both knees to chest. Hold and breathe deeply.',
    gif: '/data/videos/0690-QFmz6ch.gif',
  },
]

const updateStandaloneMode = () => {
  if (!import.meta.client) {
    standaloneMode.value = false
    return
  }
  standaloneMode.value
    = window.matchMedia('(display-mode: standalone)').matches
    // iOS Safari standalone flag.
      || Boolean(
        (window.navigator as Navigator & { standalone?: boolean }).standalone,
      )
}

const canInstall = computed(() => {
  const showInstallPrompt = Boolean(unref(pwa?.showInstallPrompt))
  const installed = isInstalled.value
  return (
    import.meta.client
      && showInstallPrompt
      && typeof pwa.install === 'function'
      && !installed
      && !standaloneMode.value
  )
})

const isInstalled = computed(
  () => Boolean(unref(pwa?.isInstalled)) || Boolean(unref(pwa?.isPWAInstalled)),
)

const installApp = async () => {
  if (!canInstall.value || !pwa.install) {
    return
  }
  await pwa.install()
}

const advancedProfile = {
  effort: 'RIR 0-1',
}

const formatWorkout = (line: string): WorkoutLine => {
  const separator = line.indexOf(' - ')
  const name = separator > -1 ? line.slice(0, separator) : line
  const plan = separator > -1 ? line.slice(separator + 3) : ''

  return {
    name,
    plan: `${plan} · ${advancedProfile.effort}`,
  }
}

const detailedWorkout = computed<WorkoutLine[]>(() => {
  return todayWorkout.value.map((line) => {
    const w = formatWorkout(line)
    return { ...w, gif: findGifForWorkout(w.name) }
  })
})

const showGifModal = ref(false)
const activeGif = ref<WorkoutLine | null>(null)
const activeGifLoaded = ref(false)
const loadedGifs = ref<Set<string>>(new Set())
const onGifLoad = (id: string) => {
  loadedGifs.value = new Set(loadedGifs.value).add(id)
}

const showTreadmillModal = ref(false)
const isTreadmillActive = ref(false)
const treadmillElapsed = ref(0)
let treadmillHandle: ReturnType<typeof setInterval> | null = null

const treadmillPlan: RunSegment[] = [
  { label: 'Warm-Up Walk', speed: '3.0 mph', incline: '1%', seconds: 300, durationLabel: '0:00-5:00' },
  { label: 'Sprint 1', speed: '8.5 mph', incline: '1%', seconds: 20, durationLabel: '5:00-5:20' },
  { label: 'Rest 1', speed: '2.5 mph', incline: '1%', seconds: 10, durationLabel: '5:20-5:30' },
  { label: 'Sprint 2', speed: '9.0 mph', incline: '1%', seconds: 20, durationLabel: '5:30-5:50' },
  { label: 'Rest 2', speed: '2.5 mph', incline: '1%', seconds: 10, durationLabel: '5:50-6:00' },
  { label: 'Sprint 3', speed: '9.0 mph', incline: '1%', seconds: 20, durationLabel: '6:00-6:20' },
  { label: 'Rest 3', speed: '2.5 mph', incline: '1%', seconds: 10, durationLabel: '6:20-6:30' },
  { label: 'Sprint 4', speed: '9.5 mph', incline: '1%', seconds: 20, durationLabel: '6:30-6:50' },
  { label: 'Rest 4', speed: '2.5 mph', incline: '1%', seconds: 10, durationLabel: '6:50-7:00' },
  { label: 'Sprint 5', speed: '9.5 mph', incline: '1%', seconds: 20, durationLabel: '7:00-7:20' },
  { label: 'Rest 5', speed: '2.5 mph', incline: '1%', seconds: 10, durationLabel: '7:20-7:30' },
  { label: 'Sprint 6', speed: '10.0 mph', incline: '1%', seconds: 20, durationLabel: '7:30-7:50' },
  { label: 'Rest 6', speed: '2.5 mph', incline: '1%', seconds: 10, durationLabel: '7:50-8:00' },
  { label: 'Sprint 7', speed: '10.0 mph', incline: '1%', seconds: 20, durationLabel: '8:00-8:20' },
  { label: 'Rest 7', speed: '2.5 mph', incline: '1%', seconds: 10, durationLabel: '8:20-8:30' },
  { label: 'Sprint 8', speed: '10.5 mph', incline: '1%', seconds: 20, durationLabel: '8:30-8:50' },
  { label: 'Rest 8', speed: '2.5 mph', incline: '1%', seconds: 10, durationLabel: '8:50-9:00' },
  { label: 'Cool-Down Walk', speed: '3.0 mph', incline: '1%', seconds: 180, durationLabel: '9:00-12:00' },
]

const treadmillTotalSeconds = treadmillPlan.reduce(
  (sum, seg) => sum + seg.seconds,
  0,
)

const currentTreadmillSegmentIndex = computed(() => {
  let acc = 0
  for (let i = 0; i < treadmillPlan.length; i += 1) {
    acc += treadmillPlan[i]!.seconds
    if (treadmillElapsed.value < acc) {
      return i
    }
  }
  return treadmillPlan.length - 1
})

const currentTreadmillSegment = computed(
  () => treadmillPlan[currentTreadmillSegmentIndex.value]!,
)
const nextTreadmillSegment = computed(
  () => treadmillPlan[currentTreadmillSegmentIndex.value + 1] || null,
)
const nextNextTreadmillSegment = computed(
  () => treadmillPlan[currentTreadmillSegmentIndex.value + 2] || null,
)

const treadmillClockLabel = computed(() => {
  const remaining = Math.max(treadmillTotalSeconds - treadmillElapsed.value, 0)
  const mins = Math.floor(remaining / 60)
  const secs = remaining % 60
  return `${mins}:${String(secs).padStart(2, '0')}`
})

const stopTreadmillInterval = () => {
  if (treadmillHandle !== null) {
    clearInterval(treadmillHandle)
    treadmillHandle = null
  }
}

const toggleTreadmill = () => {
  if (isTreadmillActive.value) {
    isTreadmillActive.value = false
    stopTreadmillInterval()
    return
  }
  if (treadmillElapsed.value >= treadmillTotalSeconds) {
    treadmillElapsed.value = 0
  }
  isTreadmillActive.value = true
  treadmillHandle = setInterval(() => {
    if (treadmillElapsed.value >= treadmillTotalSeconds) {
      isTreadmillActive.value = false
      stopTreadmillInterval()
      return
    }
    treadmillElapsed.value += 1
  }, 1000)
}

const resetTreadmill = () => {
  isTreadmillActive.value = false
  stopTreadmillInterval()
  treadmillElapsed.value = 0
}

const closeTreadmill = () => {
  showTreadmillModal.value = false
  isTreadmillActive.value = false
  stopTreadmillInterval()
}

const openGifModal = (item: WorkoutLine) => {
  activeGif.value = item
  activeGifLoaded.value = false
  showGifModal.value = true
}

const closeGifModal = () => {
  showGifModal.value = false
  activeGif.value = null
  activeGifLoaded.value = false
}

onMounted(() => {
  updateStandaloneMode()
  window.addEventListener('appinstalled', updateStandaloneMode)

  if (import.meta.client) {
    fetch('/data/exercises.json')
      .then(res => res.json())
      .then((data: ExerciseRecord[]) => {
        exerciseDb.value = data
      })
      .catch(err => console.log('Failed to load exercises:', err))
  }

  const raw = localStorage.getItem(STORE_KEY)
  if (!raw) {
    return
  }
  try {
    const saved = JSON.parse(raw) as Partial<WorkoutState>
    if (saved.sessionType && sessionTypes.some(t => t.id === saved.sessionType)) {
      state.sessionType = saved.sessionType
    }
    if (saved.sessionId && workoutSessions.some(s => s.id === saved.sessionId)) {
      state.sessionId = saved.sessionId
    }
    if (Array.isArray(saved.sessionHistory)) {
      state.sessionHistory = saved.sessionHistory
    }
  }
  catch {
    localStorage.removeItem(STORE_KEY)
  }
})

onUnmounted(() => {
  stopRunTimerInterval()
  stopSessionInterval()
  stopTreadmillInterval()
})

watch(
  () => ({ ...state }),
  () => {
    if (import.meta.client) {
      localStorage.setItem(STORE_KEY, JSON.stringify(state))
    }
  },
  { deep: true },
)
</script>
