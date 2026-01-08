# plaiReel Web Strategy

> Drive organic traffic from app shares to web, convert web visitors to app users.

---

## The Viral Loop

```
┌─────────────────────────────────────────────────┐
│                     APP                         │
│  User creates game → Shares to Twitter/WhatsApp │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼ (share link)
             plaireel.com/g/abc123
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│                     WEB                         │
│  Friend clicks → Plays game in browser →        │
│  Sees "Get the App" → Downloads → Creates games │
└─────────────────────────────────────────────────┘
```

---

## App Changes Required

### 1. Share Button on Every Game
- Add share icon to game card actions
- Generates link: `plaireel.com/g/{gameId}`
- Opens native share sheet (WhatsApp, Twitter, Instagram, Copy Link)

### 2. Share Profile
- `plaireel.com/@{username}`
- Creators share their profile to promote all their games

### 3. Deep Links (Future)
- When someone clicks web link and has app installed → opens in app
- Use Firebase Dynamic Links or similar

---

## Minimal Web Pages (Catch Shared Traffic)

You don't need a full web app. Just these pages:

### `/g/{gameId}` - Game Page
```
┌────────────────────────────────────┐
│  [plaiReel logo]     [Get App]    │
├────────────────────────────────────┤
│                                    │
│         PLAYABLE GAME              │
│         (HTML5 iframe)             │
│                                    │
├────────────────────────────────────┤
│  Game Title                        │
│  by @username • 1.2K plays         │
│                                    │
│  [♥ Like]  [💬 Comment]  [↗ Share] │
├────────────────────────────────────┤
│  ┌────────────────────────────┐   │
│  │  Create your own AI games  │   │
│  │  [Download plaiReel]       │   │
│  └────────────────────────────┘   │
├────────────────────────────────────┤
│  More games by @username           │
│  [game] [game] [game]              │
└────────────────────────────────────┘
```

**SEO Meta Tags:**
```html
<title>Game Title | plaiReel</title>
<meta name="description" content="Play this AI-generated game by @username. Create your own games with AI on plaiReel.">
<meta property="og:title" content="Game Title">
<meta property="og:description" content="Play this game on plaiReel">
<meta property="og:image" content="thumbnail.jpg">
<meta property="og:url" content="plaireel.com/g/abc123">
```

### `/@{username}` - Profile Page
```
┌────────────────────────────────────┐
│  [plaiReel logo]     [Get App]    │
├────────────────────────────────────┤
│      [Avatar]                      │
│      @username                     │
│      Display Name                  │
│      Bio text here...              │
│                                    │
│   12 Games  •  1.5K Plays  •  340 ♥│
├────────────────────────────────────┤
│  Games                             │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
│  │game1│ │game2│ │game3│ │game4│  │
│  └─────┘ └─────┘ └─────┘ └─────┘  │
├────────────────────────────────────┤
│  ┌────────────────────────────┐   │
│  │  Create your own AI games  │   │
│  │  [Download plaiReel]       │   │
│  └────────────────────────────┘   │
└────────────────────────────────────┘
```

---

## Tech Stack for Web

### Option A: Simple Static Site (Fastest)
- **Cloudflare Pages** (free hosting)
- Single HTML template
- Fetches game data from existing Cloudflare Worker
- Deploy in 1 day

### Option B: Next.js (Better SEO)
- Server-side rendering for SEO
- Same Cloudflare Worker backend
- Same Firebase database
- Deploy on Vercel (free tier)

---

## SEO Strategy

### Automatic SEO from User Activity
Every game created = new indexed page:
- `plaireel.com/g/jumping-ninja-abc123`
- `plaireel.com/g/space-shooter-def456`

Every user = new indexed page:
- `plaireel.com/@gamecreator123`
- `plaireel.com/@aiartist`

### Target Keywords
- "play ai games"
- "ai game generator"
- "create games with ai"
- "ai made games"
- "play browser games"

### Future Content Pages
- `/explore` - Browse all games
- `/trending` - Popular games
- `/new` - Latest games
- `/tags/arcade` - Games by category
- `/blog/how-to-create-ai-games` - SEO content

---

## Implementation Phases

### Phase 1: App Share Feature (1-2 days)
- [ ] Add share button to game cards
- [ ] Generate shareable URLs
- [ ] Native share sheet integration
- [ ] Copy link functionality

### Phase 2: Minimal Web (2-3 days)
- [ ] Buy domain: plaireel.com
- [ ] Set up Cloudflare Pages
- [ ] Create `/g/{gameId}` page template
- [ ] Create `/@{username}` page template
- [ ] Add "Get the App" CTAs
- [ ] Add Open Graph meta tags

### Phase 3: SEO Optimization (Ongoing)
- [ ] Submit sitemap to Google
- [ ] Add structured data (JSON-LD)
- [ ] Monitor Google Search Console
- [ ] Create blog content

### Phase 4: Deep Links (Future)
- [ ] Set up Firebase Dynamic Links
- [ ] Web links open app if installed
- [ ] Fallback to web if app not installed

---

## Success Metrics

| Metric | How to Track |
|--------|--------------|
| Shares from app | Analytics event on share button |
| Web page views | Cloudflare Analytics |
| App downloads from web | UTM params on store links |
| SEO traffic | Google Search Console |
| Conversion rate | Web visits → App installs |

---

## Why This Works

| Channel | Google Control? | You Own It? |
|---------|-----------------|-------------|
| Play Store | Yes | No |
| plaireel.com | No | **Yes** |
| SEO Traffic | No | **Yes** |
| Shared Links | No | **Yes** |
| Email List | No | **Yes** |

Even if Google removes the app, you have:
- Web presence with all games playable
- SEO traffic coming in
- Brand recognition
- Direct user relationships

---

## Quick Wins

1. **Add share button today** - Start generating shareable links
2. **Buy domain this week** - Secure plaireel.com
3. **Simple landing page** - Even just "Coming to web soon" with email signup
4. **Track shares** - See which games get shared most

---

## Notes

- Games are already HTML5 = instant web playability
- Same Cloudflare Worker = no new backend needed
- Same Firebase = no data migration
- Progressive rollout = low risk

---

*Last updated: January 2025*
