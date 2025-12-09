'use client'

import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { Capture, CaptureCategory } from '@/types'
import { generateId } from './utils'

interface CaptureStore {
  // State
  captures: Capture[]
  isLoading: boolean
  error: string | null

  // Actions
  addCapture: (capture: Omit<Capture, 'id' | 'created_at'>) => void
  updateCapture: (id: string, updates: Partial<Capture>) => void
  deleteCapture: (id: string) => void
  archiveCapture: (id: string) => void
  setCaptures: (captures: Capture[]) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void

  // Selectors
  getActiveCaptures: () => Capture[]
  getCapturesByCategory: (category: CaptureCategory) => Capture[]
  searchCaptures: (query: string) => Capture[]
}

export const useCaptureStore = create<CaptureStore>()(
  persist(
    (set, get) => ({
      // Initial state
      captures: [],
      isLoading: false,
      error: null,

      // Actions
      addCapture: (capture) => {
        const newCapture: Capture = {
          ...capture,
          id: generateId(),
          created_at: new Date().toISOString(),
        }
        set((state) => ({
          captures: [newCapture, ...state.captures],
        }))
      },

      updateCapture: (id, updates) => {
        set((state) => ({
          captures: state.captures.map((c) =>
            c.id === id ? { ...c, ...updates } : c
          ),
        }))
      },

      deleteCapture: (id) => {
        set((state) => ({
          captures: state.captures.filter((c) => c.id !== id),
        }))
      },

      archiveCapture: (id) => {
        set((state) => ({
          captures: state.captures.map((c) =>
            c.id === id ? { ...c, is_archived: true } : c
          ),
        }))
      },

      setCaptures: (captures) => {
        set({ captures })
      },

      setLoading: (isLoading) => {
        set({ isLoading })
      },

      setError: (error) => {
        set({ error })
      },

      // Selectors
      getActiveCaptures: () => {
        return get().captures.filter((c) => !c.is_archived)
      },

      getCapturesByCategory: (category) => {
        return get()
          .captures.filter((c) => !c.is_archived && c.category === category)
      },

      searchCaptures: (query) => {
        const lowerQuery = query.toLowerCase()
        return get().captures.filter((c) => {
          if (c.is_archived) return false
          if (c.title?.toLowerCase().includes(lowerQuery)) return true
          if (c.transcript?.toLowerCase().includes(lowerQuery)) return true
          if (c.tags.some((t) => t.toLowerCase().includes(lowerQuery))) return true
          return false
        })
      },
    }),
    {
      name: 'capsule-storage',
      // Only persist captures, not loading/error state
      partialize: (state) => ({ captures: state.captures }),
    }
  )
)
