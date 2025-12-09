# Game Review System - Master Implementation Plan

**Date:** December 2, 2025  
**Status:** Ready for Implementation  
**Version:** 1.3

---

## Overview

This document provides the master implementation plan for the game review system. It serves as the entry point and roadmap, with detailed specifications broken into feature-specific documents.

---

## Implementation Order & Dependencies

Follow this order to ensure proper dependencies:

### 📋 Phase 1: Foundation (Weeks 1-4) - START HERE

**Document:** `20251202_database_models.md`  
**Dependencies:** None  
**Deliverables:**

- All database migrations
- Core models with associations and validations
- Background job infrastructure (Solid Queue)
- User role system (user, moderator, admin)
- Authorization policies (Pundit)
- Email service configuration

**Why First:** Everything else depends on the database schema and authorization system.

---

### 🎮 Phase 2: Game Discovery (Weeks 5-8)

**Documents:**

1. `20251202_game_discovery.md` - Game browsing, search, filtering
2. `20251202_media_management.md` - Screenshots and videos
3. `20251202_ui_specifications.md` - Page layouts and design

**Dependencies:** Phase 1 (Game, Platform, Genre models)  
**Deliverables:**

- Game detail pages
- Platform and genre browsing
- Search functionality with filters
- Screenshot/video display
- SEO optimization

**Why Second:** Establishes the core browsing experience before adding reviews.

---

### 📰 Phase 3: Critic Reviews (Weeks 9-10)

**Document:** `20251202_critic_review_system.md`

**Dependencies:** Phase 1 (Game, Publication models) + Phase 2 (Game detail pages)  
**Deliverables:**

- Publication management
- Critic review submission (admin only)
- Metascore calculation algorithm
- Critic review display on game pages
- Rating category labels

**Why Third:** Adds professional reviews before opening to users.

---

### ✍️ Phase 4: User Reviews (Weeks 11-14)

**Document:** `20251202_user_review_system.md`

**Dependencies:** Phase 1 (UserReview model, authorization) + Phase 2 (Game pages) + Phase 3 (Review display patterns)  
**Deliverables:**

- User review submission form
- Review moderation system
- User score calculation
- Review display with filtering/sorting
- User profile pages
- Review edit history (paper_trail)
- Draft auto-save
- GDPR compliance

**Why Fourth:** Most complex feature, needs foundation + UI patterns from critic reviews.

---

### 🏆 Phase 5: Community Features (Weeks 15-16)

**Document:** `20251202_gamification.md`

**Dependencies:** Phase 4 (UserReview, user profiles)  
**Deliverables:**

- Review helpfulness voting
- User reputation system
- Achievement badges
- Review reporting system
- Spam prevention measures

**Why Fifth:** Enhances user engagement after core review system works.

---

### ⚡ Phase 6: Optimization & Polish (Weeks 17-18)

**Document:** `20251202_nfr_and_testing.md`

**Dependencies:** All previous phases  
**Deliverables:**

- Performance optimization (indexes, caching)
- Background job processing for score calculations
- GameStats aggregate table
- Mobile UI refinements
- Accessibility improvements

**Why Sixth:** Optimize based on real implementation insights.

---

### 🚀 Phase 7: Launch Preparation (Weeks 19-20)

**Document:** `20251202_nfr_and_testing.md`

**Dependencies:** All previous phases  
**Deliverables:**

- Final QA testing
- Security audit
- Load testing
- Documentation
- Soft launch with beta users

**Why Last:** Final validation before production launch.

---

## Feature Documents

### Core Documents (Read First)

| Document                      | Phase | Description                                   | Size   |
| ----------------------------- | ----- | --------------------------------------------- | ------ |
| **This Document**             | -     | Master roadmap and implementation order       | Small  |
| `20251202_database_models.md` | 1     | Database schema, models, migrations           | Large  |
| `20251202_nfr_and_testing.md` | 6-7   | Non-functional requirements, testing strategy | Medium |

### Feature Documents (Read When Needed)

| Document                           | Phase | Description                           | Size   |
| ---------------------------------- | ----- | ------------------------------------- | ------ |
| `20251202_game_discovery.md`       | 2     | Search, filtering, browse pages       | Medium |
| `20251202_media_management.md`     | 2     | Screenshots, videos, galleries        | Small  |
| `20251202_critic_review_system.md` | 3     | Critic reviews, metascore calculation | Medium |
| `20251202_user_review_system.md`   | 4     | User reviews, moderation, scoring     | Large  |
| `20251202_gamification.md`         | 5     | Profiles, reputation, badges, voting  | Medium |
| `20251202_ui_specifications.md`    | 2-7   | All UI/UX details, page layouts       | Large  |

---

## User Stories Summary

### Phase 1-3: Core Experience

- **US-1:** Browse games by platform ✅
- **US-2:** See critic and user scores ✅
- **US-3:** Read detailed reviews ✅
- **US-5:** See gameplay videos/screenshots ✅

### Phase 4: User Reviews

- **US-7:** Write reviews ✅
- **US-8:** Rate difficulty and playtime ✅
- **US-9:** Specify platform ✅
- **US-10:** Edit reviews ✅
- **US-11:** Track review history ✅

### Phase 4-5: Moderation & Community

- **US-4:** Filter by completion status ✅
- **US-6:** Mark reviews helpful ✅
- **US-12:** Review flagged content (moderator) ✅
- **US-13:** Approve/reject reviews (moderator) ✅
- **US-14:** See user reputation (moderator) ✅

### Phase 8+ (Post-Launch)

- **US-15 to US-17:** Publisher/developer features ⏳

---

## Quick Start Checklist

Before starting Phase 1, ensure you have:

- ✅ User authentication (OAuth) - **COMPLETE**
- ✅ Database (PostgreSQL) - **COMPLETE**
- ✅ CI/CD pipeline - **COMPLETE**
- ⏳ Design system/UI library
- ⏳ Asset CDN setup
- ⏳ External API keys (IGDB, OpenCritic, YouTube)

---

## Technology Stack

**Backend:** Ruby on Rails 8.1+, PostgreSQL, Redis, Solid Queue  
**Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS, ViewComponent  
**Storage:** ActiveStorage, CloudFront/CDN  
**Search:** PostgreSQL full-text search (pg_search gem)  
**Auth:** Pundit for authorization  
**Monitoring:** Sentry, New Relic or Scout APM  
**Email:** SendGrid or Postmark

---

## External APIs (Free/Low-Cost)

1. **IGDB API** - Game metadata and images (Free: 4 req/sec)
2. **OpenCritic API** - Critic reviews (Free for non-commercial)
3. **YouTube API** - Video embeds (Free: 10k quota/day)

---

## How to Use This Plan

1. **Start with Phase 1:** Read `20251202_database_models.md` and implement all migrations
2. **Work sequentially:** Each phase builds on previous ones
3. **Reference as needed:** Check feature docs when implementing that phase
4. **Update as you learn:** Add notes about implementation challenges
5. **Don't skip phases:** Dependencies are critical for system integrity

---

## Document Version History

**Version 1.3** (December 2, 2025)

- Split monolithic feature doc into modular documents
- Added clear implementation order with dependencies
- Created master roadmap for easier navigation

**Version 1.2** (December 2, 2025)

- Streamlined from v1.1, removed business content
- Fixed version inconsistencies
- Removed cost estimates and vague API references

**Version 1.1** (December 2, 2025)

- Applied code review recommendations
- Added background jobs, user roles, GDPR compliance to Phase 1 & 4
- Added Authorization & Roles section

---

## Related Documents

- **Code Review:** `docs/review/20251202_game_review_system_analysis.md`
- **Streamlined Review:** `docs/review/20251202_game_review_system_streamlined_review.md`
- **Original Monolithic Doc:** `docs/features/20251202_game_review_system.md` (archived)

---

**Next Step:** Read `20251202_database_models.md` and begin Phase 1 implementation.
