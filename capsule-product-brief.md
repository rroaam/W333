# Capsule

**Smart voice capture for ideas, visions, reflections, and plans.**

## One-liner
Capsule is an instant voice capture app that helps you record and organize fleeting thoughts before they disappear.

## The Problem
Great ideas come at inconvenient times. By the time you open a notes app and start typing, the thought is half-gone. Voice memos exist, but they become a graveyard of unlabeled audio files.

## The Solution
Capsule lets you capture voice instantly with one tap, categorized by intent from the start:
- **IDEA** - Creative sparks and inventions
- **VISION** - Long-term goals and dreams
- **REFLECT** - Personal thoughts and feelings
- **PLANS** - Tasks and actionable items

## Key Features
- **Instant capture** - Widget on lock screen / home screen
- **Intent-first** - Pick category before recording (not after)
- **3-minute limit** - Forces concise, focused thoughts
- **AI transcription** - Searchable text from every recording
- **Cross-device sync** - iOS app + web PWA, same account

## Design Language
- Hardware-device aesthetic (like a physical voice recorder)
- Dot matrix / LED visualizations
- Near-black background (#111111)
- Monospace typography
- Heavy haptic feedback

## Category Colors
| Category | Hex | Use |
|----------|-----|-----|
| IDEA | #FFE066 | Yellow - creative, bright |
| VISION | #66D9FF | Cyan - expansive, future |
| REFLECT | #66FF99 | Green - calm, grounded |
| PLANS | #FF8566 | Coral - urgent, actionable |

## Tech Stack
- **iOS**: SwiftUI, WidgetKit, AVFoundation
- **Web**: Next.js 14, Tailwind, Framer Motion
- **Backend**: Supabase (Auth, Postgres, Storage)
- **AI**: OpenAI Whisper (transcription), GPT-4 (insights)

## Taglines
- "Capture thoughts before they vanish"
- "One tap. One thought. Done."
- "Your voice, organized by intent"
- "The voice recorder that actually works"
