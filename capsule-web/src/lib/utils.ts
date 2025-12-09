import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

// Merge Tailwind classes safely
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Format duration as MM:SS
export function formatDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

// Format relative time (e.g., "2h ago", "Yesterday")
export function formatRelativeTime(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMins / 60)
  const diffDays = Math.floor(diffHours / 24)

  if (diffMins < 1) return 'Just now'
  if (diffMins < 60) return `${diffMins}m ago`
  if (diffHours < 24) return `${diffHours}h ago`
  if (diffDays === 1) return 'Yesterday'
  if (diffDays < 7) return `${diffDays}d ago`

  return date.toLocaleDateString()
}

// Truncate text with ellipsis
export function truncate(text: string, length: number): string {
  if (text.length <= length) return text
  return text.slice(0, length) + '...'
}

// Generate unique ID
export function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
}

// Haptic feedback (for supported browsers)
export function haptic(style: 'light' | 'medium' | 'heavy' = 'medium') {
  if ('vibrate' in navigator) {
    const duration = style === 'light' ? 10 : style === 'medium' ? 25 : 50
    navigator.vibrate(duration)
  }
}

// Play system sound (using Web Audio API)
export function playSound(type: 'click' | 'start' | 'stop' | 'success' | 'warning') {
  const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)()
  const oscillator = audioContext.createOscillator()
  const gainNode = audioContext.createGain()

  oscillator.connect(gainNode)
  gainNode.connect(audioContext.destination)

  const sounds: Record<string, { freq: number; duration: number; type: OscillatorType }> = {
    click: { freq: 1000, duration: 0.05, type: 'sine' },
    start: { freq: 880, duration: 0.1, type: 'sine' },
    stop: { freq: 440, duration: 0.1, type: 'sine' },
    success: { freq: 1200, duration: 0.15, type: 'sine' },
    warning: { freq: 300, duration: 0.2, type: 'square' },
  }

  const sound = sounds[type]
  oscillator.type = sound.type
  oscillator.frequency.setValueAtTime(sound.freq, audioContext.currentTime)
  gainNode.gain.setValueAtTime(0.1, audioContext.currentTime)
  gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + sound.duration)

  oscillator.start(audioContext.currentTime)
  oscillator.stop(audioContext.currentTime + sound.duration)
}
