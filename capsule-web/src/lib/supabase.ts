import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types'

// Supabase configuration
// In production, these come from environment variables
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''

// Create Supabase client
export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey)

// Helper to check if Supabase is configured
export const isSupabaseConfigured = () => {
  return supabaseUrl.length > 0 && supabaseAnonKey.length > 0
}

// Auth helpers
export const signInWithMagicLink = async (email: string) => {
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${window.location.origin}/auth/callback`,
    },
  })
  return { error }
}

export const signOut = async () => {
  const { error } = await supabase.auth.signOut()
  return { error }
}

export const getCurrentUser = async () => {
  const { data: { user }, error } = await supabase.auth.getUser()
  return { user, error }
}

// Capture CRUD operations
export const fetchCaptures = async (userId: string) => {
  const { data, error } = await supabase
    .from('captures')
    .select('*')
    .eq('user_id', userId)
    .eq('is_archived', false)
    .order('created_at', { ascending: false })

  return { data, error }
}

export const createCapture = async (
  userId: string,
  category: string,
  audioBlob: Blob,
  duration: number
) => {
  // 1. Upload audio to storage
  const fileName = `${userId}/${Date.now()}.webm`
  const { error: uploadError } = await supabase.storage
    .from('audio')
    .upload(fileName, audioBlob, {
      contentType: 'audio/webm',
    })

  if (uploadError) {
    return { data: null, error: uploadError }
  }

  // 2. Get public URL
  const { data: urlData } = supabase.storage
    .from('audio')
    .getPublicUrl(fileName)

  // 3. Create capture record
  const { data, error } = await supabase
    .from('captures')
    .insert({
      user_id: userId,
      category,
      audio_url: urlData.publicUrl,
      duration,
      transcript: null,
      title: null,
      tags: [],
      is_archived: false,
    })
    .select()
    .single()

  return { data, error }
}

export const deleteCapture = async (captureId: string, audioUrl: string) => {
  // Extract file path from URL
  const urlParts = audioUrl.split('/audio/')
  const filePath = urlParts[1]

  // Delete from storage
  if (filePath) {
    await supabase.storage.from('audio').remove([filePath])
  }

  // Delete record
  const { error } = await supabase
    .from('captures')
    .delete()
    .eq('id', captureId)

  return { error }
}

export const archiveCapture = async (captureId: string) => {
  const { error } = await supabase
    .from('captures')
    .update({ is_archived: true })
    .eq('id', captureId)

  return { error }
}
