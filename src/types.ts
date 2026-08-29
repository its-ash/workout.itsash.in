export type WorkoutSession = {
  id: string
  type: 'push' | 'pull' | 'legs'
  title: string
  workout: string[]
}

export type SessionType = 'push' | 'pull' | 'legs'