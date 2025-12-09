'use client'

import { useState, useRef, useCallback, useEffect } from 'react'
import { haptic, playSound } from '@/lib/utils'

// Maximum recording duration: 3 minutes
const MAX_DURATION = 180
const WARNING_THRESHOLD = 150

interface UseAudioRecorderReturn {
  isRecording: boolean
  duration: number
  audioLevel: number
  isApproachingLimit: boolean
  error: string | null
  startRecording: () => Promise<void>
  stopRecording: () => Promise<Blob | null>
  cancelRecording: () => void
}

export function useAudioRecorder(): UseAudioRecorderReturn {
  const [isRecording, setIsRecording] = useState(false)
  const [duration, setDuration] = useState(0)
  const [audioLevel, setAudioLevel] = useState(0)
  const [isApproachingLimit, setIsApproachingLimit] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioContextRef = useRef<AudioContext | null>(null)
  const analyserRef = useRef<AnalyserNode | null>(null)
  const chunksRef = useRef<Blob[]>([])
  const timerRef = useRef<NodeJS.Timeout | null>(null)
  const levelTimerRef = useRef<NodeJS.Timeout | null>(null)
  const startTimeRef = useRef<number>(0)

  // Clean up on unmount
  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
      if (levelTimerRef.current) clearInterval(levelTimerRef.current)
      if (audioContextRef.current) audioContextRef.current.close()
    }
  }, [])

  const startRecording = useCallback(async () => {
    try {
      setError(null)
      chunksRef.current = []

      // Request microphone access
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          sampleRate: 44100,
        }
      })

      // Set up audio context for level metering
      audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)()
      const source = audioContextRef.current.createMediaStreamSource(stream)
      analyserRef.current = audioContextRef.current.createAnalyser()
      analyserRef.current.fftSize = 256
      source.connect(analyserRef.current)

      // Create MediaRecorder
      const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
        ? 'audio/webm;codecs=opus'
        : 'audio/webm'

      mediaRecorderRef.current = new MediaRecorder(stream, { mimeType })

      mediaRecorderRef.current.ondataavailable = (event) => {
        if (event.data.size > 0) {
          chunksRef.current.push(event.data)
        }
      }

      mediaRecorderRef.current.start(100) // Collect data every 100ms
      startTimeRef.current = Date.now()
      setIsRecording(true)
      setIsApproachingLimit(false)

      // Haptic + sound feedback
      haptic('heavy')
      playSound('start')

      // Start duration timer
      timerRef.current = setInterval(() => {
        const elapsed = (Date.now() - startTimeRef.current) / 1000
        setDuration(elapsed)

        // Check warning threshold
        if (elapsed >= WARNING_THRESHOLD && !isApproachingLimit) {
          setIsApproachingLimit(true)
          haptic('heavy')
          playSound('warning')
        }

        // Auto-stop at max duration
        if (elapsed >= MAX_DURATION) {
          stopRecording()
        }
      }, 100)

      // Start audio level monitoring
      levelTimerRef.current = setInterval(() => {
        if (analyserRef.current) {
          const dataArray = new Uint8Array(analyserRef.current.frequencyBinCount)
          analyserRef.current.getByteFrequencyData(dataArray)
          const average = dataArray.reduce((a, b) => a + b) / dataArray.length
          setAudioLevel(average / 255) // Normalize to 0-1
        }
      }, 50)

    } catch (err) {
      console.error('Failed to start recording:', err)
      setError('Microphone access denied. Please allow microphone access.')
      haptic('heavy')
    }
  }, [isApproachingLimit])

  const stopRecording = useCallback(async (): Promise<Blob | null> => {
    return new Promise((resolve) => {
      if (!mediaRecorderRef.current || !isRecording) {
        resolve(null)
        return
      }

      // Clear timers
      if (timerRef.current) clearInterval(timerRef.current)
      if (levelTimerRef.current) clearInterval(levelTimerRef.current)

      mediaRecorderRef.current.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: 'audio/webm' })

        // Stop all tracks
        mediaRecorderRef.current?.stream.getTracks().forEach(track => track.stop())

        // Clean up audio context
        if (audioContextRef.current) {
          audioContextRef.current.close()
          audioContextRef.current = null
        }

        setIsRecording(false)
        setAudioLevel(0)

        // Haptic + sound feedback
        haptic('medium')
        playSound('stop')

        resolve(blob)
      }

      mediaRecorderRef.current.stop()
    })
  }, [isRecording])

  const cancelRecording = useCallback(() => {
    if (timerRef.current) clearInterval(timerRef.current)
    if (levelTimerRef.current) clearInterval(levelTimerRef.current)

    if (mediaRecorderRef.current) {
      mediaRecorderRef.current.stream.getTracks().forEach(track => track.stop())
    }

    if (audioContextRef.current) {
      audioContextRef.current.close()
      audioContextRef.current = null
    }

    chunksRef.current = []
    setIsRecording(false)
    setDuration(0)
    setAudioLevel(0)
    setIsApproachingLimit(false)

    haptic('light')
  }, [])

  return {
    isRecording,
    duration,
    audioLevel,
    isApproachingLimit,
    error,
    startRecording,
    stopRecording,
    cancelRecording,
  }
}
