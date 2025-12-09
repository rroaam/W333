'use client'

import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { Capture, CaptureCategory } from '@/types'
import { generateId } from './utils'
import { supabase, isSupabaseConfigured } from './supabase'

interface CaptureStore {
  // State
  captures: Capture[]
  isLoading: boolean
  isSyncing: boolean
  error: string | null

  // Actions
  addCapture: (capture: Omit<Capture, 'id' | 'created_at'>, audioBlob?: Blob) => Promise<Capture>
  updateCapture: (id: string, updates: Partial<Capture>) => void
  deleteCapture: (id: string) => Promise<void>
  archiveCapture: (id: string) => void
  setCaptures: (captures: Capture[]) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void

  // Cloud sync
  syncWithCloud: (userId: string) => Promise<void>
  uploadToCloud: (userId: string, capture: Capture, audioBlob: Blob) => Promise<void>

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
      isSyncing: false,
      error: null,

      // Actions
      addCapture: async (capture, audioBlob) => {
        const newCapture: Capture = {
          ...capture,
          id: generateId(),
          created_at: new Date().toISOString(),
        }
        set((state) => ({
          captures: [newCapture, ...state.captures],
        }))
        return newCapture
      },

      updateCapture: (id, updates) => {
        set((state) => ({
          captures: state.captures.map((c) =>
            c.id === id ? { ...c, ...updates } : c
          ),
        }))
      },

      deleteCapture: async (id) => {
        const capture = get().captures.find(c => c.id === id)

        // Delete from cloud if it has a cloud URL
        if (capture?.audio_url?.includes('supabase')) {
          try {
            const urlParts = capture.audio_url.split('/audio/')
            const filePath = urlParts[1]
            if (filePath) {
              await supabase.storage.from('audio').remove([filePath])
            }
            await supabase.from('captures').delete().eq('id', id)
          } catch (e) {
            console.error('Failed to delete from cloud:', e)
          }
        }

        // Always delete locally
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

        // Update in cloud
        if (isSupabaseConfigured()) {
          supabase.from('captures').update({ is_archived: true }).eq('id', id)
        }
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

      // Cloud sync - fetch captures from Supabase
      syncWithCloud: async (userId: string) => {
        if (!isSupabaseConfigured()) return

        set({ isSyncing: true, error: null })

        try {
          const { data, error } = await supabase
            .from('captures')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })

          if (error) throw error

          if (data) {
            // Merge cloud captures with local (cloud takes precedence for matching IDs)
            const localCaptures = get().captures
            const cloudIds = new Set(data.map(c => c.id))
            const localOnly = localCaptures.filter(c => !cloudIds.has(c.id))

            // Transform cloud data to match our type
            const cloudCaptures: Capture[] = data.map(c => ({
              id: c.id,
              user_id: c.user_id,
              category: c.category as CaptureCategory,
              audio_url: c.audio_url || '',
              transcript: c.transcript,
              title: c.title,
              tags: c.tags || [],
              duration: c.duration,
              is_archived: c.is_archived,
              created_at: c.created_at,
            }))

            set({ captures: [...cloudCaptures, ...localOnly] })
          }
        } catch (e) {
          console.error('Sync failed:', e)
          set({ error: 'Failed to sync with cloud' })
        } finally {
          set({ isSyncing: false })
        }
      },

      // Upload a capture to cloud storage
      uploadToCloud: async (userId: string, capture: Capture, audioBlob: Blob) => {
        if (!isSupabaseConfigured()) return

        try {
          // 1. Upload audio file
          const fileName = `${userId}/${capture.id}.webm`
          const { error: uploadError } = await supabase.storage
            .from('audio')
            .upload(fileName, audioBlob, {
              contentType: 'audio/webm',
              upsert: true,
            })

          if (uploadError) throw uploadError

          // 2. Get signed URL (private bucket)
          const { data: urlData } = await supabase.storage
            .from('audio')
            .createSignedUrl(fileName, 60 * 60 * 24 * 365) // 1 year

          const audioUrl = urlData?.signedUrl || ''

          // 3. Create capture record
          const { error: insertError } = await supabase
            .from('captures')
            .insert({
              id: capture.id,
              user_id: userId,
              category: capture.category,
              audio_url: audioUrl,
              audio_file_path: fileName,
              duration: capture.duration,
              transcript: capture.transcript,
              title: capture.title,
              tags: capture.tags,
              is_archived: capture.is_archived,
            })

          if (insertError) throw insertError

          // 4. Update local capture with cloud URL
          get().updateCapture(capture.id, { audio_url: audioUrl })

        } catch (e) {
          console.error('Upload to cloud failed:', e)
          throw e
        }
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
