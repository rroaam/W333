'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { useAuthStore } from '@/lib/auth'
import { haptic, playSound } from '@/lib/utils'

interface AuthModalProps {
  isOpen: boolean
  onClose: () => void
}

export default function AuthModal({ isOpen, onClose }: AuthModalProps) {
  const [email, setEmail] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [sent, setSent] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const { signIn } = useAuthStore()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email.trim()) return

    haptic('medium')
    playSound('tap')
    setIsLoading(true)
    setError(null)

    const { error } = await signIn(email)

    if (error) {
      setError(error.message)
      haptic('error')
    } else {
      setSent(true)
      haptic('success')
      playSound('success')
    }

    setIsLoading(false)
  }

  const handleClose = () => {
    haptic('light')
    setEmail('')
    setSent(false)
    setError(null)
    onClose()
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4"
          onClick={handleClose}
        >
          <motion.div
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.95, opacity: 0 }}
            onClick={(e) => e.stopPropagation()}
            className="w-full max-w-md bg-[#1a1a1a] rounded-2xl p-6 border border-white/10"
          >
            {sent ? (
              <div className="text-center">
                <div className="w-16 h-16 bg-[#66FF99]/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-[#66FF99]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <h2 className="text-xl font-bold text-white mb-2">CHECK YOUR EMAIL</h2>
                <p className="text-white/60 text-sm mb-6">
                  We sent a magic link to<br />
                  <span className="text-white">{email}</span>
                </p>
                <button
                  onClick={handleClose}
                  className="w-full py-3 bg-white/10 text-white rounded-xl font-medium"
                >
                  GOT IT
                </button>
              </div>
            ) : (
              <>
                <h2 className="text-xl font-bold text-white mb-2">SIGN IN</h2>
                <p className="text-white/60 text-sm mb-6">
                  Enter your email to sync captures across devices
                </p>

                <form onSubmit={handleSubmit}>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="your@email.com"
                    className="w-full px-4 py-3 bg-[#111111] text-white rounded-xl border border-white/10 focus:border-white/30 focus:outline-none mb-4 font-mono"
                    disabled={isLoading}
                    autoFocus
                  />

                  {error && (
                    <p className="text-[#FF8566] text-sm mb-4">{error}</p>
                  )}

                  <button
                    type="submit"
                    disabled={isLoading || !email.trim()}
                    className="w-full py-3 bg-white text-black rounded-xl font-bold disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isLoading ? 'SENDING...' : 'SEND MAGIC LINK'}
                  </button>
                </form>

                <button
                  onClick={handleClose}
                  className="w-full py-3 text-white/60 mt-4 text-sm"
                >
                  CONTINUE WITHOUT ACCOUNT
                </button>
              </>
            )}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
