'use client'

import { CATEGORIES, type Capture } from '@/types'
import { formatDuration, formatRelativeTime, truncate, haptic } from '@/lib/utils'
import { cn } from '@/lib/utils'

interface CaptureCardProps {
  capture: Capture
  onClick: () => void
}

export function CaptureCard({ capture, onClick }: CaptureCardProps) {
  const category = CATEGORIES[capture.category]

  const handleClick = () => {
    haptic('light')
    onClick()
  }

  return (
    <button
      onClick={handleClick}
      className="card p-4 w-full text-left btn-press transition-transform active:scale-[0.98]"
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-2">
        <span
          className="text-xs px-2 py-0.5 rounded font-mono"
          style={{
            backgroundColor: `${category.color}20`,
            color: category.color,
          }}
        >
          {category.icon} {category.label}
        </span>
        <span className="text-xs text-capsule-muted font-mono flex items-center gap-1">
          <WaveformIcon />
          {formatDuration(capture.duration)}
        </span>
      </div>

      {/* Title */}
      <h3 className="text-white font-medium mb-1 line-clamp-2">
        {capture.title || `Untitled ${capture.category.toLowerCase()}`}
      </h3>

      {/* Transcript preview */}
      {capture.transcript && (
        <p className="text-sm text-capsule-muted line-clamp-2 mb-2">
          {truncate(capture.transcript, 100)}
        </p>
      )}

      {/* Footer */}
      <p className="text-xs text-capsule-muted/70">
        {formatRelativeTime(capture.created_at)}
      </p>
    </button>
  )
}

function WaveformIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 12 12" fill="currentColor">
      <rect x="0" y="4" width="2" height="4" rx="1" />
      <rect x="3" y="2" width="2" height="8" rx="1" />
      <rect x="6" y="3" width="2" height="6" rx="1" />
      <rect x="9" y="4" width="2" height="4" rx="1" />
    </svg>
  )
}

interface CategoryBadgeProps {
  category: Capture['category']
  isActive?: boolean
}

export function CategoryBadge({ category, isActive }: CategoryBadgeProps) {
  const cat = CATEGORIES[category]

  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded font-mono',
        isActive ? 'text-capsule-bg' : ''
      )}
      style={{
        backgroundColor: isActive ? cat.color : `${cat.color}20`,
        color: isActive ? '#111' : cat.color,
      }}
    >
      {cat.icon} {cat.label}
    </span>
  )
}
