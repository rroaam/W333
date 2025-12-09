'use client'

import { create } from 'zustand'
import { supabase, isSupabaseConfigured } from './supabase'
import type { User } from '@supabase/supabase-js'

interface AuthStore {
  user: User | null
  isLoading: boolean
  isConfigured: boolean

  initialize: () => Promise<void>
  signIn: (email: string) => Promise<{ error: Error | null }>
  signOut: () => Promise<void>
}

export const useAuthStore = create<AuthStore>((set, get) => ({
  user: null,
  isLoading: true,
  isConfigured: false,

  initialize: async () => {
    const configured = isSupabaseConfigured()
    set({ isConfigured: configured })

    if (!configured) {
      set({ isLoading: false })
      return
    }

    // Get initial session
    const { data: { session } } = await supabase.auth.getSession()
    set({ user: session?.user ?? null, isLoading: false })

    // Listen for auth changes
    supabase.auth.onAuthStateChange((_event, session) => {
      set({ user: session?.user ?? null })
    })
  },

  signIn: async (email: string) => {
    if (!get().isConfigured) {
      return { error: new Error('Supabase not configured') }
    }

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${window.location.origin}/`,
      },
    })
    return { error }
  },

  signOut: async () => {
    if (!get().isConfigured) return
    await supabase.auth.signOut()
    set({ user: null })
  },
}))
