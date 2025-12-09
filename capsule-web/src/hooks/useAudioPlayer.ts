'use client'

import { useState, useRef, useCallback, useEffect } from 'react'
import { haptic } from '@/lib/utils'

interface UseAudioPlayerReturn {
  isPlaying: boolean
  currentTime: number
  duration: number
  progress: number
  load: (url: string) => void
  play: () => void
  pause: () => void
  toggle: () => void
  seek: (progress: number) => void
  skipForward: (seconds?: number) => void
  skipBackward: (seconds?: number) => void
}

export function useAudioPlayer(): UseAudioPlayerReturn {
  const [isPlaying, setIsPlaying] = useState(false)
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)

  const audioRef = useRef<HTMLAudioElement | null>(null)
  const animationRef = useRef<number | null>(null)

  // Clean up on unmount
  useEffect(() => {
    return () => {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current)
      }
      if (audioRef.current) {
        audioRef.current.pause()
      }
    }
  }, [])

  const updateProgress = useCallback(() => {
    if (audioRef.current) {
      setCurrentTime(audioRef.current.currentTime)
      if (isPlaying) {
        animationRef.current = requestAnimationFrame(updateProgress)
      }
    }
  }, [isPlaying])

  const load = useCallback((url: string) => {
    if (audioRef.current) {
      audioRef.current.pause()
    }

    const audio = new Audio(url)
    audioRef.current = audio

    audio.addEventListener('loadedmetadata', () => {
      setDuration(audio.duration)
      setCurrentTime(0)
    })

    audio.addEventListener('ended', () => {
      setIsPlaying(false)
      setCurrentTime(0)
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current)
      }
    })

    audio.addEventListener('error', (e) => {
      console.error('Audio error:', e)
      setIsPlaying(false)
    })
  }, [])

  const play = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.play()
      setIsPlaying(true)
      haptic('light')
      animationRef.current = requestAnimationFrame(updateProgress)
    }
  }, [updateProgress])

  const pause = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause()
      setIsPlaying(false)
      haptic('light')
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current)
      }
    }
  }, [])

  const toggle = useCallback(() => {
    if (isPlaying) {
      pause()
    } else {
      play()
    }
  }, [isPlaying, play, pause])

  const seek = useCallback((progress: number) => {
    if (audioRef.current && duration > 0) {
      const time = progress * duration
      audioRef.current.currentTime = time
      setCurrentTime(time)
      haptic('light')
    }
  }, [duration])

  const skipForward = useCallback((seconds: number = 10) => {
    if (audioRef.current) {
      const newTime = Math.min(audioRef.current.currentTime + seconds, duration)
      audioRef.current.currentTime = newTime
      setCurrentTime(newTime)
      haptic('light')
    }
  }, [duration])

  const skipBackward = useCallback((seconds: number = 10) => {
    if (audioRef.current) {
      const newTime = Math.max(audioRef.current.currentTime - seconds, 0)
      audioRef.current.currentTime = newTime
      setCurrentTime(newTime)
      haptic('light')
    }
  }, [])

  const progress = duration > 0 ? currentTime / duration : 0

  return {
    isPlaying,
    currentTime,
    duration,
    progress,
    load,
    play,
    pause,
    toggle,
    seek,
    skipForward,
    skipBackward,
  }
}
