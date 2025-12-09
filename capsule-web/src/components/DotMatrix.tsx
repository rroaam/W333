'use client'

import { useEffect, useRef } from 'react'

interface DotMatrixProps {
  audioLevel: number
  isRecording: boolean
  className?: string
}

export function DotMatrix({ audioLevel, isRecording, className }: DotMatrixProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const animationRef = useRef<number>(0)
  const phaseRef = useRef(0)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const draw = () => {
      const width = canvas.width
      const height = canvas.height
      const cols = 15
      const rows = 9
      const dotSize = 4
      const spacing = Math.min(width / cols, height / rows)
      const startX = (width - (cols - 1) * spacing) / 2
      const startY = (height - (rows - 1) * spacing) / 2
      const centerX = width / 2
      const centerY = height / 2

      ctx.clearRect(0, 0, width, height)

      phaseRef.current += 0.02

      for (let row = 0; row < rows; row++) {
        for (let col = 0; col < cols; col++) {
          const x = startX + col * spacing
          const y = startY + row * spacing

          // Calculate distance from center
          const dx = x - centerX
          const dy = y - centerY
          const distance = Math.sqrt(dx * dx + dy * dy)
          const maxDistance = Math.sqrt(centerX * centerX + centerY * centerY)
          const normalizedDistance = distance / maxDistance

          // Calculate opacity
          let opacity: number
          if (isRecording) {
            // Ripple effect based on audio level
            const ripple = Math.sin((normalizedDistance * 3 - phaseRef.current) * Math.PI * 2)
            const baseOpacity = 0.15
            const audioContribution = audioLevel * 0.5
            const rippleContribution = (ripple + 1) / 2 * 0.3 * audioLevel
            opacity = Math.min(1, baseOpacity + audioContribution + rippleContribution)
          } else {
            // Idle animation
            const wave = Math.sin(normalizedDistance * 2 + phaseRef.current * 2) * 0.5 + 0.5
            opacity = 0.1 + wave * 0.1
          }

          ctx.beginPath()
          ctx.arc(x, y, dotSize / 2, 0, Math.PI * 2)
          ctx.fillStyle = `rgba(255, 255, 255, ${opacity})`
          ctx.fill()
        }
      }

      animationRef.current = requestAnimationFrame(draw)
    }

    // Set canvas size
    const resizeCanvas = () => {
      const rect = canvas.getBoundingClientRect()
      canvas.width = rect.width * window.devicePixelRatio
      canvas.height = rect.height * window.devicePixelRatio
      ctx.scale(window.devicePixelRatio, window.devicePixelRatio)
    }

    resizeCanvas()
    window.addEventListener('resize', resizeCanvas)
    draw()

    return () => {
      window.removeEventListener('resize', resizeCanvas)
      cancelAnimationFrame(animationRef.current)
    }
  }, [audioLevel, isRecording])

  return (
    <canvas
      ref={canvasRef}
      className={className}
      style={{ width: '100%', height: '100%' }}
    />
  )
}
