# Capsule Web

A Progressive Web App for smart voice capture - the web companion to the Capsule iOS app.

## Features

- Record voice memos with 4 categories (IDEA, VISION, REFLECT, PLANS)
- 3-minute maximum recording with countdown warnings
- Local storage with optional Supabase cloud sync
- PWA: installable on mobile, works offline
- Same design system as the iOS app

## Quick Start

```bash
# Install dependencies
npm install

# Run development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Deploy to Vercel

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/YOUR_USERNAME/capsule-web)

Or deploy manually:

```bash
npm i -g vercel
vercel
```

## Environment Variables

For Supabase integration (optional), create `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Styling**: Tailwind CSS
- **Animation**: Framer Motion
- **State**: Zustand (with localStorage persistence)
- **Audio**: Web Audio API + MediaRecorder
- **Backend** (optional): Supabase (Auth, Database, Storage)

## Project Structure

```
src/
├── app/              # Next.js app router pages
├── components/       # React components
│   ├── CategoryButton.tsx
│   ├── CaptureCard.tsx
│   ├── CaptureDetail.tsx
│   ├── DotMatrix.tsx
│   └── RecordingModal.tsx
├── hooks/            # Custom React hooks
│   ├── useAudioRecorder.ts
│   └── useAudioPlayer.ts
├── lib/              # Utilities and configuration
│   ├── store.ts      # Zustand store
│   ├── supabase.ts   # Supabase client
│   └── utils.ts      # Helper functions
└── types/            # TypeScript types
    └── index.ts
```

## License

MIT
