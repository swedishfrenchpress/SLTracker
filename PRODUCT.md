# Product

## Register

product

## Users

Stockholm commuters who ride SL (metro, bus, tram, train, ferry). They check the app in transit-adjacent moments — leaving home, walking to the platform — and want the next departure time in under two seconds. Many discovered the app because the official SL app felt slow and cluttered.

## Product Purpose

SL Tracker shows real-time departures for Stockholm public transit with minimal distraction. "A simpler way to ride Stockholm." One thing done perfectly: next departures — via search, pinned stations on the home screen, and a Home Screen widget that requires no app opening. Success = the user gets their departure time faster than unlocking the official app.

## Brand Personality

Minimalist, warm, slightly irreverent. "Nothing more, nothing less." Made by one person with love ("Lovingly made by Erik in Stockholm ❤️‍🔥") — personal, not corporate. Calm confidence over feature bloat.

## Anti-references

- The official SL app: slow, cluttered, feature-stuffed.
- Generic transit dashboards with ads, maps-first UIs, and account walls.
- Onboarding carousels with stock illustrations that don't show the real product.

## Design Principles

- **Show the real product, not metaphors** — illustrations are faithful miniatures of actual UI (pinned list, widget).
- **System-native restraint** — system fonts, semantic colors, default animation curves, Liquid Glass on iOS 26 with graceful fallbacks. No custom design system.
- **Speed is the feature** — nothing may delay the departure time reaching the eye.
- **Small warm touches, sparingly** — one easter egg, one loving footer; delight at moments, never noise.

## Accessibility & Inclusion

- Every animation gated by Reduce Motion (`accessibilityReduceMotion`), degrading to `.none`.
- Semantic colors only (full automatic dark mode); VoiceOver labels on icon buttons.
- English UI, Swedish station names; no localization yet.
