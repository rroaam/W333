'use client'

import { useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { CATEGORIES, type Capture } from '@/types'
import { CategoryBadge } from './CaptureCard'
import { useAudioPlayer } from '@/hooks/useAudioPlayer'
import { formatDuration, formatRelativeTime, haptic, playSound } from '@/lib/utils'
import { useCaptureStore } from '@/lib/store'

interface CaptureDetailProps {
  capture: Capture | null
  isOpen: boolean
  onClose: () => void
}

export function CaptureDetail({ capture, isOpen, onClose }: CaptureDetailProps) {
  const {
    isPlaying,
    currentTime,
    duration,
    progress,
    load,
    toggle,
    skipForward,
    skipBackward,
  } = useAudioPlayer()

  const deleteCapture = useCaptureStore((s) => s.deleteCapture)
  const archiveCapture = useCaptureStore((s) => s.archiveCapture)

  useEffect(() => {
    if (capture && isOpen) {
      load(capture.audio_url)
    }
  }, [capture, isOpen, load])

  if (!capture) return null

  const categoryInfo = CATEGORIES[capture.category]

  const handleDelete = () => {
    haptic('heavy')
    playSound('warning')
    deleteCapture(capture.id)
    onClose()
  }

  const handleArchive = () => {
    haptic('medium')
    archiveCapture(capture.id)
    onClose()
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0, y: '100%' }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: '100%' }}
          transition={{ type: 'spring', damping: 25, stiffness: 300 }}
          className="fixed inset-0 z-50 bg-capsule-bg overflow-auto"
        >
          <div className="min-h-full p-6 safe-area-top safe-area-bottom">
            {/* Header */}
            <div className="flex items-center justify-between mb-6">
              <button
                onClick={onClose}
                className="text-capsule-muted text-sm btn-press"
              >
                Close
              </button>

              <div className="flex gap-2">
                <button
                  onClick={handleArchive}
                  className="text-capsule-muted text-sm btn-press"
                >
                  Archive
                </button>
                <button
                  onClick={handleDelete}
                  className="text-red-500 text-sm btn-press"
                >
                  Delete
                </button>
              </div>
            </div>

            {/* Title section */}
            <div className="mb-6">
              <CategoryBadge category={capture.category} />
              <h1 className="text-2xl font-medium mt-3 mb-1">
                {capture.title || `Untitled ${capture.category.toLowerCase()}`}
              </h1>
              <p className="text-sm text-capsule-muted">
                {formatRelativeTime(capture.created_at)}
              </p>
            </div>

            {/* Audio player */}
            <div className="card p-4 mb-6">
              {/* Waveform */}
              <div className="h-16 flex items-center gap-1 mb-4">
                {Array.from({ length: 40 }).map((_, i) => {
                  const height = 0.3 + Math.sin(i * 0.5) * 0.2 + Math.random() * 0.3
                  const isPast = i / 40 <= progress
                  return (
                    <div
                      key={i}
                      className="flex-1 rounded-full transition-colors"
                      style={{
                        height: `${height * 100}%`,
                        backgroundColor: isPast ? 'white' : 'rgba(255,255,255,0.2)',
                      }}
                    />
                  )
                })}
              </div>

              {/* Time */}
              <div className="flex justify-between text-xs text-capsule-muted font-mono mb-4">
                <span>{formatDuration(currentTime)}</span>
                <span>{formatDuration(duration || capture.duration)}</span>
              </div>

              {/* Controls */}
              <div className="flex items-center justify-center gap-8">
                <button
                  onClick={() => skipBackward()}
                  className="text-capsule-muted btn-press"
                >
                  <SkipBackIcon />
                </button>

                <button
                  onClick={toggle}
                  className="w-14 h-14 rounded-full bg-white flex items-center justify-center btn-press"
                >
                  {isPlaying ? <PauseIcon /> : <PlayIcon />}
                </button>

                <button
                  onClick={() => skipForward()}
                  className="text-capsule-muted btn-press"
                >
                  <SkipForwardIcon />
                </button>
              </div>
            </div>

            {/* Transcript section */}
            <div className="card p-4 mb-6">
              <h2 className="text-xs text-capsule-muted font-mono tracking-wider mb-3">
                TRANSCRIPT
              </h2>
              {capture.transcript ? (
                <p className="text-white">{capture.transcript}</p>
              ) : (
                <p className="text-capsule-muted text-sm italic">
                  Transcription available in a future update
                </p>
              )}
            </div>

            {/* Tags */}
            {capture.tags.length > 0 && (
              <div className="card p-4 mb-6">
                <h2 className="text-xs text-capsule-muted font-mono tracking-wider mb-3">
                  TAGS
                </h2>
                <div className="flex flex-wrap gap-2">
                  {capture.tags.map((tag) => (
                    <span
                      key={tag}
                      className="text-sm px-2 py-1 rounded"
                      style={{
                        backgroundColor: `${categoryInfo.color}20`,
                        color: categoryInfo.color,
                      }}
                    >
                      #{tag}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Metadata */}
            <div className="card p-4">
              <h2 className="text-xs text-capsule-muted font-mono tracking-wider mb-3">
                DETAILS
              </h2>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-capsule-muted">Duration</span>
                  <span className="font-mono">{formatDuration(capture.duration)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-capsule-muted">Created</span>
                  <span>{new Date(capture.created_at).toLocaleString()}</span>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

function PlayIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="#111">
      <path d="M8 5v14l11-7z" />
    </svg>
  )
}

function PauseIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="#111">
      <rect x="6" y="4" width="4" height="16" />
      <rect x="14" y="4" width="4" height="16" />
    </svg>
  )
}

function SkipBackIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <polygon points="11 19 2 12 11 5 11 19" />
      <line x1="22" y1="5" x2="22" y2="19" />
    </svg>
  )
}

function SkipForwardIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <polygon points="13 19 22 12 13 5 13 19" />
      <line x1="2" y1="5" x2="2" y2="19" />
    </svg>
  )
}
