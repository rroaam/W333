// Capsule data types - shared structure with iOS app

export type CaptureCategory = 'IDEA' | 'VISION' | 'REFLECT' | 'PLANS'

export interface Capture {
  id: string
  user_id: string
  category: CaptureCategory
  audio_url: string
  transcript: string | null
  title: string | null
  tags: string[]
  duration: number // in seconds
  created_at: string
  is_archived: boolean
}

// For creating new captures (before they have an ID)
export interface NewCapture {
  category: CaptureCategory
  audio_blob: Blob
  duration: number
}

// Category metadata
export const CATEGORIES: Record<CaptureCategory, {
  label: string
  icon: string
  color: string
}> = {
  IDEA: {
    label: 'IDEA',
    icon: '💡',
    color: '#FFE066',
  },
  VISION: {
    label: 'VISION',
    icon: '🎯',
    color: '#66D9FF',
  },
  REFLECT: {
    label: 'REFLECT',
    icon: '✓',
    color: '#66FF99',
  },
  PLANS: {
    label: 'PLANS',
    icon: '📅',
    color: '#FF8566',
  },
}

// Database types for Supabase
export interface Database {
  public: {
    Tables: {
      captures: {
        Row: Capture
        Insert: Omit<Capture, 'id' | 'created_at'>
        Update: Partial<Omit<Capture, 'id'>>
      }
    }
  }
}
