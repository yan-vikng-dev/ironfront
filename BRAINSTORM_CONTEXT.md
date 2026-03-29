	var raw_body: Variant = post_result.unwrap()
	var body: Dictionary = raw_body if raw_body is Dictionary else {}# Brainstorming Session Context

Carried over from a chat in the ThreatLight repo (March 29, 2026).

## About Me (Yan)

- Fullstack dev, now "everything software" at a cybersecurity company (ThreatLight)
- Skills: fullstack web, DevOps (GCP/Docker/Terraform), fleet management, observability, AI agents, game dev (Godot)
- Portfolio: https://vikng.dev
- Projects: ThreatLight (production SaaS), FlowCost (expense tracker for nomads, stalled), AutoQuit (macOS tool), Ironfront (Godot Android tank game), Grix (Web3 options aggregator)
- Non-compete: can't work with companies in the cybersecurity space specifically
- No existing audience or distribution channel (LinkedIn/Reddit only, nothing special)
- Available time: 2-4 hours/day, 7 days/week
- Goal: passive income (build once + self-running systems). Slow burn is fine, current job covers lifestyle.

## Key Insights from the Session

1. **Skills surplus, distribution deficit.** Can build almost anything but nobody knows I exist. Every path forward must solve distribution.
2. **Finishing problem.** FlowCost hit 80%, game stalled, WhatsApp bot shelved. Working alone with no external accountability is the root cause.
3. **WhatsApp AI bot was the most interesting signal.** 3 nomads in Thailand said the bot was more interesting than the FlowCost website. The insight is about the *channel* (WhatsApp-first), not just the feature.
4. **Game dev is the passion** but hardest to monetize solo. Content about building the game may be more valuable than the game itself.

## Three Paths Identified (ranked by fit)

### Path 1: WhatsApp AI agent for small businesses (highest conviction)
- Not expense tracking — booking/ordering/customer service for small businesses via WhatsApp
- Already have both halves: WhatsApp Business API integration + AI agent experience
- Target: WhatsApp-heavy markets (LATAM, SEA, India, parts of Europe)
- Start narrow: one vertical (e.g., appointment booking for barber shops), 5 pilot customers, $30-50/mo
- Fits the "self-running system" goal perfectly

### Path 2: Ship the game + document it on YouTube (passion play)
- Godot content is underserved (post-Unity exodus)
- YouTube builds the missing distribution, every video compounds
- The game is ~2 weeks from MVP if I sit down and push through
- Biggest current blocker: Godot client -> TypeScript user data server -> Postgres translations/validations
- Documenting on video creates external accountability (fixes the finishing problem)

### Path 3: Productized DevOps for startups (cash-flow bridge, optional)
- Fixed-scope offer: "GCP + Docker + Terraform + CI/CD in one week for $2-3K"
- Not passive, but funds the other two while building reputation
- Sell on Reddit/Indie Hackers/LinkedIn

## Proposed Timeline

| Timeframe | Action |
|---|---|
| Weeks 1-2 | Finish and ship tank game to Google Play. Record the process. |
| Weeks 3-4 | Edit and post 2-3 YouTube videos. Set up channel. |
| Month 2-3 | Build WhatsApp AI booking bot MVP. Pick one vertical. Keep posting devlogs. |
| Month 4 | Get 5 paying pilot customers for the WhatsApp bot. |
| Ongoing | 1 video + 1 feature per week. Build in public. |

## Next Steps (for the game specifically)

- Unblock the Godot -> TypeScript -> Postgres pipeline
- Ship MVP to Google Play (no monetization needed yet, just ship)
- Start recording devlog content during the process
