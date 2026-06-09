# Scripture Memorizer App — Product Requirements Document

**Document version:** 1.0  
**Last updated:** May 25, 2026  
**Status:** Draft for development kickoff  
**Platforms:** iOS, Android (mobile-first)

---

## 1. Product Overview & Vision

### 1.1 Summary

The **Scripture Memorizer App** is a faith-based mobile application that helps users memorize Bible scriptures through guided reading, listening, repetition, recitation, and interactive practice. The product serves children (6–12), teenagers (13–19), and adults with age-appropriate experiences, high-quality text-to-speech (TTS), multilingual scripture content, and progress tracking that encourages daily habit formation.

### 1.2 Vision

To become the most trusted, joyful, and effective scripture memorization companion for families and individuals—making God’s Word accessible, memorable, and part of everyday life across languages, ages, and learning styles.

### 1.3 Problem Statement

Many people want to memorize scripture but struggle with consistency, effective techniques, and engaging practice—especially children and busy adults. Existing Bible apps often prioritize reading and study over **structured memorization**, spaced repetition, and **multi-modal learning** (read, hear, speak, type).

### 1.4 Solution

A dedicated memorization app that combines:

- Curated and searchable scripture library
- **Daily Verse** for habit-building
- Five memorization modes: **Read, Listen, Repeat, Recite, Fill-in-the-Blank**
- **Repeat/Loop Mode** with user-defined repetition counts
- Premium-quality TTS with voice and speed customization by age group
- Progress, streaks, favorites, and optional cloud sync
- Freemium access with clear upgrade value

### 1.5 Product Principles

| Principle | Description |
|-----------|-------------|
| **Faith-first** | Respectful, accurate scripture presentation; no gamification that trivializes sacred text |
| **Age-appropriate** | UI, voices, and pacing adapt to child, teen, and adult profiles |
| **Habit over hype** | Streaks and daily verse support sustainable practice, not vanity metrics |
| **Accessible** | Offline-capable core flows; TTS for auditory learners; multilingual support |
| **Transparent monetization** | Free tier is genuinely useful; premium unlocks depth, not basics |

---

## 2. Target Audience

### 2.1 Primary Segments

| Segment | Age | Needs | Typical use cases |
|---------|-----|-------|-------------------|
| **Children** | 6–12 | Simple UI, short verses, visual/audio guidance, parental trust | Sunday school memory verses, family devotions |
| **Teenagers** | 13–19 | Modern UX, streaks, favorites, peer/family accountability | Youth group challenges, personal growth |
| **Adults** | 20+ | Efficient workflows, offline, multiple translations, progress history | Daily devotional memorization, sermon prep |

### 2.2 Secondary Personas

| Persona | Role | Goals |
|---------|------|-------|
| **Parent / Guardian** | Supervises child accounts (future) or shared device | Safe content, progress visibility, age-appropriate voices |
| **Teacher / Leader** | Church, school, small group | Assign verses, track group progress (roadmap) |
| **Guest user** | Tries app before account | Quick access to daily verse and limited memorization |

### 2.3 User Assumptions

- Users have intermittent connectivity; offline memorization is important for adults and travelers
- Children may use shared devices or supervised accounts
- Premium subscribers expect cloud backup, extended library, and full TTS/voice options

---

## 3. Objectives & Goals

### 3.1 Business Objectives

| Objective | Target (12 months post-launch) |
|-----------|--------------------------------|
| User acquisition | 50K+ downloads (combined stores) |
| Premium conversion | 5–8% of MAU on paid plan |
| Retention | D7 ≥ 35%, D30 ≥ 20% for active memorizers |
| App store rating | ≥ 4.5 stars with emphasis on ease of use and TTS quality |

### 3.2 User Objectives

| Objective | How the app delivers |
|-----------|----------------------|
| Memorize specific verses | Browse/search, favorites, five practice modes |
| Build daily habit | Daily Verse, streaks, reminders (push, roadmap) |
| Learn by listening | TTS with male/female and age-specific voices |
| Practice in native language | Multiple translations and UI localization (phased) |
| Track improvement | Progress per verse, completion states, streak calendar |

### 3.3 Product Goals (MVP)

1. Ship core memorization loop (select verse → practice → mark progress) on iOS and Android
2. Launch freemium with monthly and yearly premium subscriptions
3. Support guest mode plus email/social login (platform-standard)
4. Deliver reliable offline access for saved verses and in-progress memorization
5. Meet non-functional targets for performance, accessibility, and child-safety posture

---

## 4. Core Features (MVP vs Premium)

### 4.1 Feature Matrix

| Feature | Free (MVP) | Premium |
|---------|------------|---------|
| Browse & search scriptures | Limited catalog (e.g., top 100 verses, NT/OT samples) | Full library, all books/chapters |
| Daily Verse | Yes | Yes + history archive |
| Memorization modes (all 5) | Yes (with daily limits optional) | Unlimited sessions |
| Repeat/Loop Mode | Up to 10× per session | 5×, 10×, 25×, unlimited |
| TTS voices | 1–2 default voices | Male/Female, Child/Teen/Adult voices |
| TTS speed & pitch | Fixed or narrow range | Full adjustable range |
| Translations | 1–2 bundled (e.g., KJV, NIV) | Many languages/translations |
| Favorites | Up to 10 verses | Unlimited |
| Progress & streaks | Yes | Yes + detailed analytics |
| Offline mode | Saved verses + last daily verse | Full library offline download |
| Cloud sync | No | Cross-device sync |
| Login / Signup / Guest | Yes | Yes |
| Ads | None (faith app) or minimal—product decision | Ad-free guaranteed |

### 4.2 Feature Specifications

#### 4.2.1 Scripture Library — Browse & Search

- **Browse:** By book → chapter → verse; curated lists (e.g., “Verses of Comfort,” “Memory Verses for Kids”)
- **Search:** Reference (John 3:16), keyword, topic tags
- **Verse detail:** Reference, text, translation label, actions (Favorite, Start Memorizing, Listen, Loop)

#### 4.2.2 Daily Verse

- One verse per calendar day (global or profile timezone)
- Push notification opt-in: “Your verse for today is ready”
- Quick actions: Read, Listen, Memorize, Share (image card, roadmap)

#### 4.2.3 Memorization Modes

| Mode | Description | Acceptance criteria |
|------|-------------|---------------------|
| **Read** | Display verse; user reads silently or aloud | Adjustable font size; line highlighting optional |
| **Listen** | TTS plays verse; user follows along | Play/pause, replay, voice selection (premium) |
| **Repeat** | User repeats after TTS or with Loop count | Integrates with Repeat/Loop Mode |
| **Recite** | Verse hidden; user speaks; speech recognition checks (phase 2) or self-check tap | MVP: tap to reveal word-by-word or line-by-line |
| **Fill-in-the-Blank** | Random words blanked; user selects or types answers | Configurable difficulty (% blanks) |

**Session end:** Score or completion %, option to save progress, add to favorites, set reminder.

#### 4.2.4 Repeat / Loop Mode

- User selects verse and repetition count: **5×, 10×, 25×, Unlimited** (premium for 25× and unlimited)
- Each iteration: TTS reads verse (or display-only for Read loop)
- Progress indicator: “3 of 10”
- Pause, skip, exit with confirmation
- Optional short break every N loops (settings)

#### 4.2.5 Text-to-Speech (TTS)

| Capability | Detail |
|------------|--------|
| Voice gender | Male, Female |
| Age profiles | Child, Teen, Adult (timbre/style presets) |
| Controls | Speed (0.5×–2.0×), pitch (low–high) |
| Quality | Platform neural voices where available; fallback to high-quality bundled or cloud TTS |
| Offline | Cached audio for favorited verses (premium priority) |

#### 4.2.6 Translations & Languages

- MVP: Minimum 2 English translations; UI in English
- Premium / Phase 2: Spanish, French, Portuguese, etc.; UI localization
- Store translation metadata (abbreviation, copyright notice)

#### 4.2.7 Authentication & Guest Mode

| Mode | Capabilities |
|------|----------------|
| **Guest** | Daily verse, limited browse, local progress (device-only) |
| **Registered** | Persistent profile, favorites, streaks, optional cloud sync |
| **Signup/Login** | Email + password; Sign in with Apple / Google per store policy |

**Guest → Account migration:** Prompt to merge local progress on signup.

#### 4.2.8 Favorites

- One-tap favorite from verse detail and post-session
- Favorites list sorted by date added or reference
- Swipe to remove; empty state with suggestions

#### 4.2.9 Progress Tracking & Streaks

- **Per verse:** Not started / In progress / Memorized (user or threshold-based)
- **Streak:** Consecutive days with ≥1 completed memorization session (configurable minimum duration)
- **Dashboard:** Current streak, longest streak, verses memorized count, recent activity

#### 4.2.10 Offline Mode

- Download packs: Favorites, selected chapters, or “Memorizing now” queue
- Daily verse cached when online; fallback to last cached if offline
- Clear storage management in Settings

#### 4.2.11 Cloud Sync (Premium)

- Sync favorites, progress, streaks, settings across devices
- Conflict resolution: last-write-wins with timestamp; log for support
- Requires account + active subscription

---

## 5. User Flows & Navigation

### 5.1 Information Architecture

```
App Root
├── Home (Daily Verse, Continue Memorizing, Streak summary)
├── Browse
│   ├── Books / Curated Lists
│   └── Verse Detail
├── Memorize
│   ├── Mode Selector (Read | Listen | Repeat | Recite | Fill-in-Blank)
│   └── Session / Results
├── Favorites
├── Progress (Stats, Streak calendar, Memorized list)
├── Premium / Upgrade
└── Profile & Settings
    ├── Account (Login / Signup / Guest banner)
    ├── Voice & TTS settings
    ├── Offline downloads
    ├── Notifications
    └── About / Legal / Subscription management
```

### 5.2 Primary User Flows

#### Flow A: First launch (Guest)

1. Splash → optional onboarding (age group, goals)
2. Home with Daily Verse
3. Tap “Memorize” → mode selection → complete session
4. Prompt: Create account to save streak (skippable)

#### Flow B: Memorize a chosen verse

1. Browse or Search → Verse Detail
2. Tap “Start Memorizing” → select mode
3. If Listen/Repeat: choose voice (premium) and loop count if Repeat
4. Complete session → Results → Favorite / Continue / Home

#### Flow C: Repeat / Loop Mode

1. Verse Detail → “Loop” or Repeat mode
2. Select count (5 / 10 / 25 / Unlimited)
3. Session runs with counter and controls
4. Summary: loops completed, time spent

#### Flow D: Premium upgrade

1. Hit limit (e.g., 11th favorite, 25× loop, locked translation)
2. Paywall modal: benefits table, monthly vs yearly (highlight savings)
3. Store purchase → unlock features → restore purchases in Settings

#### Flow E: Offline use

1. Settings → Download favorites or chapter pack (premium: full library)
2. Offline indicator on Home
3. Memorize and Listen use cached TTS where available

### 5.3 Navigation Patterns

- **Bottom tab bar (5 tabs):** Home, Browse, Memorize (or center action), Favorites, Progress
- **Profile/Settings:** Avatar or gear from Home header
- **Child mode (optional MVP+):** Simplified tabs, larger touch targets, reduced copy

---

## 6. Technical Requirements

### 6.1 Platform & Stack (Recommended)

| Layer | Recommendation |
|-------|----------------|
| Mobile | React Native or Flutter for shared iOS/Android codebase |
| Backend | Firebase or Supabase (auth, Firestore/DB, cloud functions) |
| Auth | Email, Apple Sign-In, Google Sign-In |
| Subscriptions | RevenueCat or native StoreKit / Play Billing |
| TTS | Platform APIs (AVSpeechSynthesizer, Android TTS) + cloud fallback (Azure/Google) for premium voices |
| Analytics | Privacy-compliant (Firebase Analytics, Amplitude) |
| CMS (optional) | Headless CMS for Daily Verse and curated lists |

### 6.2 Data Model (Core Entities)

| Entity | Key fields |
|--------|------------|
| `User` | id, email, age_group, premium_status, created_at |
| `Verse` | id, book, chapter, verse, text, translation_id |
| `Translation` | id, code, name, language, license |
| `UserProgress` | user_id, verse_id, status, percent, last_practiced_at |
| `Favorite` | user_id, verse_id, added_at |
| `Streak` | user_id, current_count, longest_count, last_activity_date |
| `Session` | user_id, verse_id, mode, loops, duration, completed_at |
| `OfflinePack` | user_id, verse_ids, size_bytes, downloaded_at |

### 6.3 API & Sync

- REST or GraphQL for verse catalog (CDN-cached JSON acceptable for MVP)
- Authenticated endpoints for sync: `POST /sync`, `GET /profile/progress`
- Idempotent session uploads for analytics

### 6.4 Security & Privacy

- COPPA-aware flows for under-13 (minimal data collection, parental gate for account creation—jurisdiction-dependent)
- Encrypt data in transit (TLS 1.2+); encrypt sensitive local storage
- Privacy Policy and Terms of Service linked in app and stores
- GDPR/CCPA: export/delete account data

### 6.5 Integrations

| Integration | Purpose |
|-------------|---------|
| App Store / Play Store | Subscriptions, restore purchases |
| Push (FCM/APNs) | Daily verse reminders |
| Scripture API or licensed bundle | Verse text (ensure licensing) |

### 6.6 Licensing

- Secure rights to publish Bible translations per region
- Display copyright per translation in verse detail and About

---

## 7. Monetization Strategy

### 7.1 Model

**Freemium** with subscription-based Premium. No ads in MVP (aligns with faith-based trust); revisit only with explicit stakeholder approval.

### 7.2 Pricing (Illustrative — validate with market research)

| Plan | Price (USD) | Notes |
|------|-------------|-------|
| Monthly Premium | $4.99 / month | Lower commitment |
| Yearly Premium | $39.99 / year (~33% savings) | Default highlighted on paywall |
| Free trial | 7 days (yearly plan) | Store-managed intro offer |

### 7.3 Paywall Triggers

- Attempting 25× or unlimited loop
- Adding favorite beyond free limit
- Selecting locked translation or premium voice
- Cloud sync / full offline library
- Optional: daily session cap for free tier (e.g., 3 sessions/day)—A/B test

### 7.4 Revenue Principles

- Free tier must complete a meaningful memorization journey
- Paywall copy emphasizes spiritual growth and features, not guilt
- Family Sharing per store rules where applicable (roadmap)

---

## 8. Non-Functional Requirements

### 8.1 Performance

| Metric | Target |
|--------|--------|
| Cold start | < 3 seconds to interactive Home |
| Verse load | < 500 ms from local cache |
| TTS start latency | < 1 second after tap Play |
| Sync operation | < 5 seconds for typical profile |

### 8.2 Reliability & Availability

- 99.5% uptime for sync/auth services (monthly)
- Graceful degradation offline; no data loss on crash (persist session state)

### 8.3 Accessibility

- WCAG 2.1 AA orientation: screen reader labels, dynamic type, sufficient contrast
- Reduce motion option respects system settings
- TTS benefits users with reading difficulties

### 8.4 Compatibility

- iOS: last 2 major versions; Android: API 26+ (or team standard)
- Phone and tablet layouts; responsive verse typography

### 8.5 Localization

- Phase 1: English UI + 2 translations
- Phase 2: UI strings in ES, FR, PT; RTL readiness for future

### 8.6 Maintainability

- Feature flags for paywall experiments and TTS providers
- Structured logging (no PII in logs); crash reporting (Crashlytics/Sentry)

### 8.7 Content & Moderation

- Preloaded scripture only; no user-generated scripture text in MVP
- Report/feedback channel in Settings

---

## 9. Success Metrics

### 9.1 North Star Metric

**Weekly Active Memorizers (WAM):** Users who complete ≥1 memorization session per week.

### 9.2 KPI Dashboard

| Category | Metric | Definition |
|----------|--------|------------|
| Acquisition | Installs, signup rate | Store downloads; % guests converting to account |
| Activation | First session completion | % new users finishing one memorization within 24h |
| Engagement | Sessions per WAU, mode mix | Avg sessions; % Listen vs Fill-in-blank |
| Retention | D1, D7, D30 | Return rates |
| Monetization | Trial start, conversion, churn | Premium funnel |
| Quality | Crash-free sessions, TTS errors | Stability |
| Spiritual habit | Streak distribution | % users with 7+ day streak |

### 9.3 Analytics Events (Minimum)

- `app_open`, `onboarding_complete`, `daily_verse_view`
- `memorize_start`, `memorize_complete` (mode, verse_id, duration)
- `loop_start`, `loop_complete` (count)
- `favorite_add`, `offline_download`
- `paywall_view`, `subscription_start`, `subscription_cancel`

### 9.4 Qualitative Success

- App store reviews mentioning ease for kids and TTS quality
- Support tickets < 2% of MAU

---

## 10. Future Roadmap

### 10.1 Phase 2 (Post-MVP, 3–6 months)

| Item | Description |
|------|-------------|
| Speech recognition Recite | Real-time scoring vs transcript |
| Parent / child profiles | Linked accounts, parental controls |
| Reminders & widgets | Home screen daily verse widget |
| Group challenges | Church/youth group shared goals |
| Additional translations | Expand language packs |
| UI localization | Non-English app interface |

### 10.2 Phase 3 (6–12 months)

| Item | Description |
|------|-------------|
| Leaderboards (opt-in) | Private groups only; no public shaming |
| Custom verse lists | User-created memorization plans |
| Apple Watch / Wear OS | Quick daily verse and streak glance |
| iPad-optimized layouts | Split view browse + memorize |
| AI coach (careful) | Suggested next verse based on progress—not doctrinal commentary |

### 10.3 Long-Term Vision

- Partnerships with publishers and ministries for licensed content packs
- Web companion for teachers to assign verses
- Accessibility: sign language video for select verses (partnership-dependent)

---

## Appendix A: MVP Release Checklist

- [ ] Browse/search with free catalog subset
- [ ] Daily Verse on Home
- [ ] All five memorization modes (Recite MVP = reveal-based)
- [ ] Repeat/Loop with 5× and 10× free; premium tiers for 25×/unlimited
- [ ] TTS with at least one voice; premium unlocks full matrix
- [ ] Guest + Login/Signup (Apple/Google)
- [ ] Favorites, progress, streaks (local; cloud if premium)
- [ ] Offline for favorites + active verse
- [ ] Subscriptions (monthly/yearly) with restore
- [ ] Privacy Policy, Terms, translation copyrights
- [ ] App Store and Play Store assets and age rating questionnaire

## Appendix B: Open Questions

| # | Question | Owner |
|---|----------|-------|
| 1 | Exact translation licenses and launch catalog? | Legal / Content |
| 2 | Speech recognition in Recite for v1 or v1.1? | Product / Eng |
| 3 | Session limits on free tier? | Product |
| 4 | COPPA: minimum age for account without parental flow? | Legal |
| 5 | Single codebase (RN/Flutter) vs native? | Engineering |

---

*This PRD is intended for engineering, design, QA, and stakeholders. Changes require version bump and approval from Product Owner.*
