'use client'

import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { CATEGORIES, type CaptureCategory } from '@/types'
import { DotMatrix } from './DotMatrix'
import { CategoryBadge } from './CaptureCard'
import { useAudioRecorder } from '@/hooks/useAudioRecorder'
import { formatDuration, haptic, playSound } from '@/lib/utils'
import { useCaptureStore } from '@/lib/store'
import { useAuthStore } from '@/lib/auth'

const MAX_DURATION = 180

interface RecordingModalProps {
  category: CaptureCategory
  isOpen: boolean
  onClose: () => void
}

export function RecordingModal({ category, isOpen, onClose }: RecordingModalProps) {
  const {
    isRecording,
    duration,
    audioLevel,
    isApproachingLimit,
    error,
    startRecording,
    stopRecording,
    cancelRecording,
  } = useAudioRecorder()

  const { addCapture, uploadToCloud } = useCaptureStore()
  const { user, isConfigured } = useAuthStore()
  const [isSaving, setIsSaving] = useState(false)

  // Start recording when modal opens
  useEffect(() => {
    if (isOpen && !isRecording && !isSaving) {
      startRecording()
    }
  }, [isOpen])

  const handleStop = async () => {
    if (!isRecording) return

    setIsSaving(true)
    const blob = await stopRecording()

    if (blob && duration > 0.5) {
      // Create object URL for local playback
      const audioUrl = URL.createObjectURL(blob)

      const capture = await addCapture({
        user_id: user?.id || 'local',
        category,
        audio_url: audioUrl,
        duration,
        transcript: null,
        title: null,
        tags: [],
        is_archived: false,
      })

      haptic('heavy')
      playSound('success')

      // Upload to cloud if user is signed in
      if (user?.id && isConfigured) {
        try {
          await uploadToCloud(user.id, capture, blob)
        } catch (e) {
          console.error('Cloud upload failed, keeping local copy:', e)
        }
      }

      // Close after brief delay
      setTimeout(() => {
        setIsSaving(false)
        onClose()
      }, 500)
    } else {
      setIsSaving(false)
      onClose()
    }
  }

  const handleCancel = () => {
    cancelRecording()
    onClose()
  }

  const timeRemaining = MAX_DURATION - duration
  const progress = duration / MAX_DURATION
  const categoryInfo = CATEGORIES[category]

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 bg-capsule-bg"
        >
          {/* Warning overlay */}
          {isApproachingLimit && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: [0.05, 0.15, 0.05] }}
              transition={{ duration: 1, repeat: Infinity }}
              className="absolute inset-0 bg-red-500 pointer-events-none"
            />
          )}

          <div className="flex flex-col h-full p-6 safe-area-top safe-area-bottom">
            {/* Header */}
            <div className="flex items-center justify-between mb-8">
              <CategoryBadge category={category} isActive />

              {isApproachingLimit && (
                <span className="text-red-500 text-sm font-mono bg-red-500/20 px-2 py-1 rounded">
                  {Math.floor(timeRemaining)}s
                </span>
              )}

              <button
                onClick={handleCancel}
                className="w-9 h-9 rounded-full bg-capsule-surface flex items-center justify-center btn-press"
              >
                <XIcon />
              </button>
            </div>

            {/* Visualization */}
            <div className="flex-1 flex flex-col items-center justify-center">
              <div className="w-full h-48 mb-8">
                <DotMatrix
                  audioLevel={audioLevel}
                  isRecording={isRecording}
                />
              </div>

              {/* Timer */}
              <div
                className="text-5xl font-mono font-light mb-4 transition-colors"
                style={{
                  color: isApproachingLimit ? '#ef4444' : 'white',
                  textShadow: isRecording
                    ? `0 0 20px ${isApproachingLimit ? '#ef444440' : categoryInfo.color + '40'}`
                    : 'none',
                }}
              >
                {formatDuration(duration)}
              </div>

              {/* Progress bar */}
              <div className="w-48 h-1 bg-capsule-stroke rounded-full overflow-hidden mb-4">
                <motion.div
                  className="h-full rounded-full"
                  style={{
                    backgroundColor: isApproachingLimit ? '#ef4444' : categoryInfo.color,
                  }}
                  animate={{ width: `${progress * 100}%` }}
                  transition={{ duration: 0.1 }}
                />
              </div>

              {/* Status */}
              <div className="flex items-center gap-2 text-sm font-mono tracking-wider">
                {isSaving ? (
                  <span style={{ color: categoryInfo.color }}>SAVING...</span>
                ) : isApproachingLimit ? (
                  <span className="text-red-500">TIME RUNNING OUT</span>
                ) : isRecording ? (
                  <>
                    <span className="w-2 h-2 rounded-full bg-red-500 animate-recording-pulse" />
                    <span className="text-white">RECORDING</span>
                  </>
                ) : (
                  <span className="text-capsule-muted">PREPARING...</span>
                )}
              </div>

              {error && (
                <p className="text-red-500 text-sm mt-4">{error}</p>
              )}
            </div>

            {/* Stop button */}
            <div className="flex flex-col items-center">
              <button
                onClick={handleStop}
                disabled={!isRecording || isSaving}
                className="relative btn-press disabled:opacity-50"
              >
                {/* Outer ring */}
                <div
                  className="w-20 h-20 rounded-full border-2 flex items-center justify-center transition-all"
                  style={{
                    borderColor: isApproachingLimit
                      ? 'rgba(239, 68, 68, 0.3)'
                      : `${categoryInfo.color}30`,
                    boxShadow: isRecording
                      ? `0 0 30px ${isApproachingLimit ? 'rgba(239, 68, 68, 0.3)' : categoryInfo.color + '30'}`
                      : 'none',
                  }}
                >
                  {/* Stop icon */}
                  <div className="w-7 h-7 rounded-lg bg-white" />
                </div>
              </button>

              <p className="text-xs text-capsule-muted mt-4 font-mono">
                {isApproachingLimit
                  ? 'Recording will auto-stop at 3:00'
                  : 'Tap to stop recording'}
              </p>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

function XIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M4 4L12 12M12 4L4 12" />
    </svg>
  )
}
