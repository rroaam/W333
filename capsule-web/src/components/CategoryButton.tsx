'use client'

import { CATEGORIES, type CaptureCategory } from '@/types'
import { cn } from '@/lib/utils'
import { haptic, playSound } from '@/lib/utils'

interface CategoryButtonProps {
  category: CaptureCategory
  isActive?: boolean
  onSelect: (category: CaptureCategory) => void
}

export function CategoryButton({ category, isActive, onSelect }: CategoryButtonProps) {
  const { label, icon, color } = CATEGORIES[category]

  const handleClick = () => {
    haptic('heavy')
    playSound('click')
    onSelect(category)
  }

  return (
    <button
      onClick={handleClick}
      className={cn(
        'flex flex-col items-center justify-center p-3 rounded-lg transition-all btn-press',
        'flex-1 min-w-0',
        isActive
          ? 'bg-white/10 border border-white/20'
          : 'hover:bg-white/5'
      )}
      style={{
        borderColor: isActive ? color : undefined,
        boxShadow: isActive ? `0 0 16px ${color}40` : undefined,
      }}
    >
      <span className="text-xl mb-1">{icon}</span>
      <span
        className={cn(
          'text-xs font-mono tracking-wider',
          isActive ? 'text-white' : 'text-capsule-muted'
        )}
        style={{ color: isActive ? color : undefined }}
      >
        {label}
      </span>
    </button>
  )
}

interface CategorySelectionBarProps {
  onSelect: (category: CaptureCategory) => void
}

export function CategorySelectionBar({ onSelect }: CategorySelectionBarProps) {
  const categories: CaptureCategory[] = ['IDEA', 'VISION', 'REFLECT', 'PLANS']

  return (
    <div className="card p-4">
      <div className="flex gap-2 mb-3">
        {categories.map((category) => (
          <CategoryButton
            key={category}
            category={category}
            onSelect={onSelect}
          />
        ))}
      </div>
      <p className="text-center text-xs text-capsule-muted font-mono tracking-[0.3em]">
        RECORD
      </p>
    </div>
  )
}
