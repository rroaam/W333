'use client'

import { useState, useMemo, useEffect } from 'react'
import { CategorySelectionBar } from '@/components/CategoryButton'
import { CaptureCard } from '@/components/CaptureCard'
import { RecordingModal } from '@/components/RecordingModal'
import { CaptureDetail } from '@/components/CaptureDetail'
import AuthModal from '@/components/AuthModal'
import { useCaptureStore } from '@/lib/store'
import { useAuthStore } from '@/lib/auth'
import { CATEGORIES, type CaptureCategory, type Capture } from '@/types'
import { cn } from '@/lib/utils'
import { haptic, playSound } from '@/lib/utils'

export default function Home() {
  const captures = useCaptureStore((s) => s.getActiveCaptures())
  const { syncWithCloud, isSyncing } = useCaptureStore()
  const { user, isLoading: authLoading, isConfigured, initialize, signOut } = useAuthStore()

  const [selectedCategory, setSelectedCategory] = useState<CaptureCategory | null>(null)
  const [filterCategory, setFilterCategory] = useState<CaptureCategory | null>(null)
  const [selectedCapture, setSelectedCapture] = useState<Capture | null>(null)
  const [isRecording, setIsRecording] = useState(false)
  const [isDetailOpen, setIsDetailOpen] = useState(false)
  const [isAuthOpen, setIsAuthOpen] = useState(false)
  const [showMenu, setShowMenu] = useState(false)

  // Initialize auth on mount
  useEffect(() => {
    initialize()
  }, [initialize])

  // Sync with cloud when user signs in
  useEffect(() => {
    if (user?.id) {
      syncWithCloud(user.id)
    }
  }, [user?.id, syncWithCloud])

  // Filter captures
  const filteredCaptures = useMemo(() => {
    if (!filterCategory) return captures
    return captures.filter((c) => c.category === filterCategory)
  }, [captures, filterCategory])

  const handleCategorySelect = (category: CaptureCategory) => {
    setSelectedCategory(category)
    setIsRecording(true)
  }

  const handleRecordingClose = () => {
    setIsRecording(false)
    setSelectedCategory(null)
  }

  const handleCaptureClick = (capture: Capture) => {
    setSelectedCapture(capture)
    setIsDetailOpen(true)
  }

  const handleDetailClose = () => {
    setIsDetailOpen(false)
    setSelectedCapture(null)
  }

  const handleFilterClick = (category: CaptureCategory | null) => {
    haptic('light')
    playSound('click')
    setFilterCategory(category)
  }

  const handleSettingsClick = () => {
    haptic('medium')
    setShowMenu(!showMenu)
  }

  const handleSignOut = async () => {
    haptic('medium')
    await signOut()
    setShowMenu(false)
  }

  return (
    <div className="min-h-screen flex flex-col safe-area-top safe-area-bottom">
      {/* Header */}
      <header className="px-4 pt-6 pb-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-mono tracking-wider">CAPSULE</h1>
            <p className="text-xs text-capsule-muted flex items-center gap-2">
              {captures.length} capture{captures.length !== 1 ? 's' : ''}
              {isSyncing && (
                <span className="flex items-center gap-1 text-[#66D9FF]">
                  <SyncIcon className="w-3 h-3 animate-spin" />
                  syncing
                </span>
              )}
            </p>
          </div>
          <div className="relative">
            <button
              onClick={handleSettingsClick}
              className={cn(
                "w-10 h-10 rounded-full flex items-center justify-center btn-press overflow-hidden",
                user ? "bg-gradient-to-br from-[#FFE066] to-[#66FF99]" : "bg-capsule-surface"
              )}
            >
              {user ? (
                <span className="text-capsule-bg font-bold text-sm">
                  {user.email?.[0].toUpperCase()}
                </span>
              ) : (
                <SettingsIcon />
              )}
            </button>

            {/* Dropdown menu */}
            {showMenu && (
              <>
                <div
                  className="fixed inset-0 z-40"
                  onClick={() => setShowMenu(false)}
                />
                <div className="absolute right-0 top-12 z-50 bg-[#1a1a1a] rounded-xl border border-white/10 py-2 min-w-48 shadow-xl">
                  {isConfigured ? (
                    user ? (
                      <>
                        <div className="px-4 py-2 border-b border-white/10">
                          <p className="text-xs text-capsule-muted">Signed in as</p>
                          <p className="text-sm truncate">{user.email}</p>
                        </div>
                        <button
                          onClick={() => syncWithCloud(user.id)}
                          className="w-full px-4 py-2 text-left text-sm hover:bg-white/5 flex items-center gap-2"
                        >
                          <SyncIcon className={cn("w-4 h-4", isSyncing && "animate-spin")} />
                          Sync now
                        </button>
                        <button
                          onClick={handleSignOut}
                          className="w-full px-4 py-2 text-left text-sm hover:bg-white/5 text-[#FF8566]"
                        >
                          Sign out
                        </button>
                      </>
                    ) : (
                      <button
                        onClick={() => {
                          setShowMenu(false)
                          setIsAuthOpen(true)
                        }}
                        className="w-full px-4 py-2 text-left text-sm hover:bg-white/5"
                      >
                        Sign in to sync
                      </button>
                    )
                  ) : (
                    <div className="px-4 py-2 text-xs text-capsule-muted">
                      Cloud sync disabled<br />
                      <span className="text-[10px] opacity-60">(Supabase not configured)</span>
                    </div>
                  )}
                </div>
              </>
            )}
          </div>
        </div>
      </header>

      {/* Category selection */}
      <div className="px-4 mb-4">
        <CategorySelectionBar onSelect={handleCategorySelect} />
      </div>

      {/* Divider */}
      <div className="h-px bg-capsule-stroke mx-4" />

      {/* Filter chips */}
      <div className="px-4 py-3 overflow-x-auto hide-scrollbar">
        <div className="flex gap-2">
          <FilterChip
            label="ALL"
            isSelected={filterCategory === null}
            onClick={() => handleFilterClick(null)}
          />
          {(Object.keys(CATEGORIES) as CaptureCategory[]).map((cat) => (
            <FilterChip
              key={cat}
              label={cat}
              color={CATEGORIES[cat].color}
              isSelected={filterCategory === cat}
              onClick={() => handleFilterClick(filterCategory === cat ? null : cat)}
            />
          ))}
        </div>
      </div>

      {/* Captures list */}
      <div className="flex-1 px-4 pb-4 overflow-auto">
        {filteredCaptures.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-center py-20">
            <WaveformIcon className="w-12 h-12 text-capsule-muted mb-4" />
            <p className="text-capsule-muted mb-2">
              {filterCategory
                ? `No ${filterCategory.toLowerCase()} captures yet`
                : 'No captures yet'}
            </p>
            <p className="text-xs text-capsule-muted/60">
              Tap a category above to start recording
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredCaptures.map((capture) => (
              <CaptureCard
                key={capture.id}
                capture={capture}
                onClick={() => handleCaptureClick(capture)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Recording modal */}
      {selectedCategory && (
        <RecordingModal
          category={selectedCategory}
          isOpen={isRecording}
          onClose={handleRecordingClose}
        />
      )}

      {/* Capture detail */}
      <CaptureDetail
        capture={selectedCapture}
        isOpen={isDetailOpen}
        onClose={handleDetailClose}
      />

      {/* Auth modal */}
      <AuthModal isOpen={isAuthOpen} onClose={() => setIsAuthOpen(false)} />
    </div>
  )
}

interface FilterChipProps {
  label: string
  color?: string
  isSelected: boolean
  onClick: () => void
}

function FilterChip({ label, color = 'white', isSelected, onClick }: FilterChipProps) {
  return (
    <button
      onClick={onClick}
      className={cn(
        'px-3 py-1.5 rounded text-xs font-mono tracking-wider transition-all btn-press whitespace-nowrap',
        isSelected
          ? 'text-capsule-bg'
          : 'border border-current'
      )}
      style={{
        backgroundColor: isSelected ? color : 'transparent',
        color: isSelected ? '#111' : color,
        borderColor: `${color}50`,
      }}
    >
      {label}
    </button>
  )
}

function SettingsIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
      <circle cx="10" cy="10" r="3" />
      <path d="M10 1.5v2M10 16.5v2M1.5 10h2M16.5 10h2M3.4 3.4l1.4 1.4M15.2 15.2l1.4 1.4M3.4 16.6l1.4-1.4M15.2 4.8l1.4-1.4" />
    </svg>
  )
}

function SyncIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.5">
      <path d="M3 10a7 7 0 0114 0M17 10a7 7 0 01-14 0" />
      <path d="M3 10l-2-2m2 2l2-2M17 10l2 2m-2-2l-2 2" />
    </svg>
  )
}

function WaveformIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 48 48" fill="currentColor">
      <rect x="4" y="18" width="6" height="12" rx="2" />
      <rect x="14" y="10" width="6" height="28" rx="2" />
      <rect x="24" y="14" width="6" height="20" rx="2" />
      <rect x="34" y="18" width="6" height="12" rx="2" />
    </svg>
  )
}
