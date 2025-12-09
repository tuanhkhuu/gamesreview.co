# Feature: Game Review System

**Date:** December 2, 2025  
**Status:** Ready for Implementation  
**Version:** 1.2

---

## User Stories

### As a Gamer

- **US-1:** I want to browse games by platform so I can find games for my console
- **US-2:** I want to see both critic and user scores so I can make informed purchase decisions
- **US-3:** I want to read detailed reviews with pros/cons so I understand game quality
- **US-4:** I want to filter reviews by completion status so I see reviews from players who finished the game
- **US-5:** I want to see gameplay videos and screenshots so I can preview the game
- **US-6:** I want to mark reviews as helpful so the best reviews rise to the top

### As a Reviewer

- **US-7:** I want to write reviews for games I've played so I can share my experience
- **US-8:** I want to rate difficulty and playtime so others know what to expect
- **US-9:** I want to specify which platform I played on so my review is accurate
- **US-10:** I want to edit my reviews after submission so I can update my thoughts
- **US-11:** I want to track my review history so I can see all my submitted reviews

### As a Content Moderator

- **US-12:** I want to review flagged content so I can maintain community standards
- **US-13:** I want to approve/reject pending reviews so I can prevent spam
- **US-14:** I want to see user reputation scores so I can identify trustworthy reviewers

### As a Game Publisher/Developer

- **US-15:** I want to claim my game page so I can provide official information
- **US-16:** I want to respond to reviews so I can engage with the community
- **US-17:** I want to see aggregated feedback so I can understand player sentiment

**Note:** US-15 to US-17 deferred to Phase 8+ (post-launch)

---

## Functional Requirements

### 1. Game Database

**FR-1.1: Game Management**

- System shall store comprehensive game information (title, description, release date, cover art)
- System shall support multiple platforms per game (PS5, Xbox, PC, Switch, etc.)
- System shall track platform-specific release dates and features
- System shall categorize games by genre with primary/secondary genres
- System shall link games to publishers and developers

**FR-1.2: Game Discovery**

- System shall provide search functionality with filters (platform, genre, release date, score)
- System shall display "New Releases" section for games released in the last 30 days
- System shall display "Upcoming Games" section for unreleased titles
- System shall show "Top Rated Games" by metascore and user score
- System shall provide genre-based browsing

**FR-1.3: Game Details Page**

- System shall display game title, description, release date, and cover art
- System shall show metascore (critic average) and user score
- System shall list all available platforms with platform-specific scores
- System shall display publisher and developer information
- System shall show rating category (Universal Acclaim, Generally Favorable, etc.)

### 2. Critic Review System

**FR-2.1: Review Aggregation**

- System shall aggregate professional critic reviews from gaming publications
- System shall store review scores (0-100 scale)
- System shall store review excerpts and links to full reviews
- System shall track publication information (name, website, logo, credibility weight)

**FR-2.2: Metascore Calculation**

- System shall calculate weighted average metascore based on publication credibility
- System shall assign weights to publications (1-10 scale)
  - Major outlets (IGN, GameSpot): Weight 10
  - Established sites: Weight 7-9
  - Smaller publications: Weight 4-6
  - Blogs: Weight 1-3
- System shall update metascore automatically when new reviews are added
- System shall display metascore with rating category label

**FR-2.3: Review Display**

- System shall display critic reviews sorted by publication weight
- System shall show review excerpts on game page (500 chars max)
- System shall provide links to full reviews on publication websites
- System shall filter reviews by platform (for platform-specific reviews)
- System shall show review date and author name

### 3. User Review System

**FR-3.1: Review Submission**

- System shall allow authenticated users to submit game reviews
- System shall require minimum review length (75 characters)
- System shall accept review scores on 0-10 scale
- System shall accept optional review title (max 100 characters)
- System shall allow users to specify platform played on
- System shall allow users to indicate completion status (playing, completed, dropped)
- System shall allow users to provide playtime in hours
- System shall allow users to rate difficulty (1-5 scale)
- System shall allow users to mark review as containing spoilers
- System shall enforce one review per user per game per platform

**FR-3.2: Review Moderation**

- System shall set new reviews to "pending" status by default
- System shall auto-approve reviews from users with good history (configurable threshold)
- System shall notify moderators of pending reviews
- System shall allow moderators to approve, reject, or flag reviews
- System shall auto-flag reviews with 5+ user reports
- System shall store moderation notes for internal reference

**FR-3.3: Review Editing**

- System shall allow users to edit their own reviews within 30 days of submission
- System shall reset review to "pending" status if edited
- System shall maintain edit history for moderation purposes

**FR-3.4: User Score Calculation**

- System shall calculate average user score from approved reviews only
- System shall convert 0-10 user scores to display format (e.g., 8.3/10)
- System shall update user score automatically when reviews are approved
- System shall show percentage breakdown (positive/mixed/negative)
  - Positive: 7-10
  - Mixed: 4-6
  - Negative: 0-3

**FR-3.5: Review Display & Filtering**

- System shall display user reviews sorted by helpfulness by default
- System shall allow sorting by: Most Recent, Most Helpful, Highest Score, Lowest Score
- System shall allow filtering by: All Reviews, Positive, Mixed, Negative
- System shall allow filtering by completion status
- System shall allow filtering by platform
- System shall display reviewer information (username, avatar, review count)
- System shall show review metadata (score, platform, playtime, difficulty, completion)

### 4. Review Helpfulness System

**FR-4.1: Voting Mechanism**

- System shall allow users to mark reviews as helpful or not helpful
- System shall enforce one vote per user per review
- System shall allow users to change their vote
- System shall display helpfulness count (e.g., "523 found this helpful")

**FR-4.2: Review Ranking**

- System shall track helpful vote count for each review
- System shall rank reviews by helpfulness score
- System shall prioritize recent helpful reviews over older ones (decay factor)
- System shall display most helpful reviews prominently

### 5. Media Management

**FR-5.1: Screenshots**

- System shall display game screenshots in a gallery
- System shall support multiple screenshots per game
- System shall allow platform-specific screenshots
- System shall support featured/highlighted screenshots
- System shall provide lightbox/modal view for full-size images
- System shall maintain display order for screenshots

**FR-5.2: Videos**

- System shall embed game trailers from YouTube/Vimeo
- System shall support multiple videos per game (trailers, gameplay, reviews)
- System shall categorize videos by type
- System shall display video thumbnails and durations
- System shall show most recent trailer prominently

### 6. User Profile & Gamification

**FR-6.1: Reviewer Profile**

- System shall display user's review history
- System shall show user's average review score
- System shall track total reviews submitted
- System shall display user join date
- System shall show user's most reviewed genres/platforms

**FR-6.2: Reputation System**

- System shall track helpful votes received
- System shall calculate user reputation score
- System shall display badges for milestones (10 reviews, 100 helpful votes, etc.)
- System shall identify trusted reviewers with verification badge

### 7. Data Aggregation & Statistics

**FR-7.1: Game Statistics**

- System shall cache aggregate statistics per game:
  - Total critic reviews
  - Total user reviews
  - Positive/mixed/negative review counts
  - Average playtime
  - Average difficulty rating
  - Completion rate percentage
- System shall update statistics via background jobs
- System shall display statistics on game detail page

**FR-7.2: Platform Statistics**

- System shall track games per platform
- System shall calculate average platform scores
- System shall identify top-rated games per platform

### 8. Search & Discovery

**FR-8.1: Search Functionality**

- System shall provide full-text search for game titles
- System shall provide autocomplete suggestions
- System shall support advanced filters:
  - Platform
  - Genre
  - Release date range
  - Score range (metascore and user score)
  - Publisher/Developer
- System shall show search results with game card preview

**FR-8.2: Browse Pages**

- System shall provide "New Releases" page
- System shall provide "Coming Soon" page
- System shall provide "Top Rated" pages (by metascore, user score, platform)
- System shall provide genre landing pages
- System shall provide platform landing pages
- System shall provide publisher/developer pages

### 9. Spam & Abuse Prevention

**FR-9.1: Rate Limiting**

- System shall limit users to 5 reviews per 24 hours
- System shall require account age > 24 hours for review submission
- System shall require verified email address for review submission

**FR-9.2: Content Filtering**

- System shall scan reviews for offensive language (profanity filter)
- System shall detect duplicate/copied content
- System shall flag suspicious patterns (repeated low scores, spam keywords)
- System shall implement CAPTCHA for suspicious accounts

**FR-9.3: Reporting System**

- System shall allow users to report inappropriate reviews
- System shall require reason for report (spam, offensive, spoilers, etc.)
- System shall track report count per review
- System shall auto-flag reviews with multiple reports

---

## Non-Functional Requirements

### Performance

- **NFR-1:** Game detail pages shall load within 2 seconds
- **NFR-2:** Search results shall return within 1 second
- **NFR-3:** System shall support 1,000 concurrent users
- **NFR-4:** Database queries shall use proper indexes for optimization
- **NFR-5:** Frequently accessed data shall be cached (Redis)

### Scalability

- **NFR-6:** System shall handle 100,000+ games
- **NFR-7:** System shall handle 1,000,000+ user reviews
- **NFR-8:** System shall support horizontal scaling for web servers
- **NFR-9:** Background jobs shall process asynchronously (Sidekiq)

### Security

- **NFR-10:** All user input shall be sanitized to prevent XSS attacks
- **NFR-11:** Review submissions shall be protected by CSRF tokens
- **NFR-12:** User authentication shall use OAuth 2.0 (existing)
- **NFR-13:** Moderator actions shall be logged for audit trail
- **NFR-14:** Sensitive data shall be encrypted at rest

### Usability

- **NFR-15:** Interface shall be mobile-responsive
- **NFR-16:** Forms shall provide real-time validation feedback
- **NFR-17:** Error messages shall be clear and actionable
- **NFR-18:** Review submission form shall auto-save drafts
- **NFR-19:** Pages shall be accessible (WCAG 2.1 Level AA)

### SEO & Discoverability

- **NFR-20:** Game URLs shall use SEO-friendly slugs (e.g., `/games/elden-ring`)
- **NFR-21:** Pages shall include meta tags (Open Graph, Twitter Cards)
- **NFR-22:** Game pages shall include structured data (Schema.org markup)
- **NFR-23:** System shall generate sitemap.xml automatically
- **NFR-24:** System shall implement canonical URLs to prevent duplicate content

### Reliability

- **NFR-25:** System shall maintain 99.9% uptime
- **NFR-26:** Database backups shall run daily
- **NFR-27:** Failed background jobs shall retry with exponential backoff
- **NFR-28:** Error monitoring shall alert team of critical issues (Sentry/Rollbar)

### Data Privacy & Compliance

- **NFR-29:** System shall comply with GDPR requirements
  - Users can export all their data in JSON format
  - Deleted user accounts shall have reviews anonymized (not deleted)
  - Cookie consent banner for tracking
  - Privacy policy and terms of service pages
- **NFR-30:** Image uploads shall be validated for file type, size (< 10MB), and content
- **NFR-31:** Video embeds shall only allow whitelisted domains (YouTube, Vimeo)
- **NFR-32:** User review edit history shall be maintained for audit purposes

---

## Technical Architecture

### Database Models

**Core Entities:**

1. **Game** - Central model for game information
2. **Platform** - Gaming platforms (PS5, Xbox, PC, Switch)
3. **GamePlatform** - Join table with platform-specific data
4. **Genre** - Game categories/genres
5. **GameGenre** - Join table for game-genre relationships
6. **Publisher** - Game publishers
7. **Developer** - Game development studios
8. **Publication** - Gaming review outlets
9. **CriticReview** - Professional critic reviews
10. **UserReview** - User-submitted reviews
11. **ReviewHelpfulnessVote** - Helpfulness voting
12. **Screenshot** - Game screenshots
13. **Video** - Game trailers and videos
14. **GameStats** - Cached aggregate statistics

**Detailed schema:** See `docs/features/20251202_database_schema_design.md`

### Authorization & Roles

**User Roles:**

- `user` - Standard registered user (can submit reviews, vote)
- `moderator` - Can approve/reject/flag reviews, manage content
- `admin` - Full system access (manage games, users, publications)
- `publisher_rep` - Publisher/developer representative (future phase)

**Authorization Framework:**

- Pundit gem for policy-based authorization
- Role-based access control (RBAC)
- Policy classes for each major resource (Game, UserReview, CriticReview)

**Implementation:**

```ruby
class User < ApplicationRecord
  enum role: {
    user: 'user',
    moderator: 'moderator',
    admin: 'admin'
    # publisher_rep: 'publisher_rep' - Phase 8+ (US-15 to US-17)
  }

  def moderator?
    role.in?(%w[moderator admin])
  end
end
```

### Technology Stack

**Backend:**

- Ruby on Rails 8.1+
- PostgreSQL (primary database)
- Redis (caching & session storage)
- Sidekiq (background job processing)

**Frontend:**

- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- ViewComponent for reusable UI components

**Storage & CDN:**

- ActiveStorage for image uploads
- CloudFront/CDN for static asset delivery

**Search:**

- PostgreSQL full-text search (pg_search gem)

**Monitoring:**

- Sentry for error tracking
- New Relic or Scout APM for performance monitoring

---

## User Interface & Experience

### Key Pages

#### 1. Home Page

- Hero section with featured games
- New releases carousel
- Top rated games by platform
- Recent user reviews
- Popular genres

#### 2. Game Detail Page

**Layout Sections:**

- **Header:** Title, cover art, metascore badge, user score badge, platforms
- **Overview:** Description, release date, publisher, developer, genres
- **Scores:** Metascore with breakdown, user score with distribution
- **Media:** Screenshot gallery, video trailers
- **Critic Reviews:** List of professional reviews with excerpts
- **User Reviews:** Filterable/sortable list with helpfulness voting
- **Related Games:** Similar games by genre/developer

#### 3. Browse/Search Pages

- Filter sidebar (platform, genre, score, release date)
- Sort options (release date, score, name)
- Grid/list view toggle
- Pagination or infinite scroll
- Game cards with: cover, title, platform icons, metascore, user score

#### 4. Review Submission Page

- Game selection (if not from game page)
- Platform selection
- Score selector (0-10 with half-points)
- Review title (optional)
- Review text (rich text editor)
- Completion status dropdown
- Hours played input
- Difficulty rating (1-5 stars)
- Spoiler checkbox
- Draft save functionality
- Preview mode

#### 5. User Profile Page

- Avatar and username
- Stats: Total reviews, average score, helpful votes received
- Achievement badges
- Review history (filterable by platform/genre)

### Design Principles

1. **Clean & Minimal:** Focus on content, minimal distractions
2. **Score-First:** Scores prominently displayed with color coding
3. **Mobile-First:** Responsive design that works on all devices
4. **Fast Loading:** Optimized images, lazy loading, progressive enhancement
5. **Accessibility:** Keyboard navigation, screen reader friendly, sufficient contrast

---

## Implementation Plan

### Phase 1: Foundation (Weeks 1-4)

**Deliverables:**

- Database schema and migrations
- Core models with associations and validations
- Basic CRUD operations for games
- Admin interface for game management (ActiveAdmin or custom)
- Seed data for testing
- **Background job infrastructure (Solid Queue)**
- **User role and permission system (user, moderator, admin)**
- **Authorization policies (Pundit)**
- **Email service configuration (SendGrid/Postmark)**

### Phase 2: Game Discovery (Weeks 5-8)

- Game detail page with full information
- Platform and genre browsing pages
- Search functionality with filters
- Screenshot and video display
- SEO optimization (meta tags, slugs, sitemap)

### Phase 3: Critic Reviews (Weeks 9-10)

- Publication model and management
- Critic review submission (admin only)
- Metascore calculation algorithm
- Critic review display on game pages
- Rating category labels

### Phase 4: User Reviews (Weeks 11-14)

- User review submission form
- Review moderation system
- User score calculation
- Review display with filtering/sorting
- User profile pages with review history
- Review edit history tracking (paper_trail gem)
- Draft auto-save functionality
- GDPR compliance (data export, review anonymization)

### Phase 5: Community Features (Weeks 15-16)

- Review helpfulness voting
- User reputation system
- Achievement badges
- Review reporting system
- Spam prevention measures

### Phase 6: Optimization & Polish (Weeks 17-18)

- Performance optimization (database indexes, caching)
- Background job processing for score calculations
- GameStats aggregate table
- Mobile UI refinements
- Accessibility improvements

### Phase 7: Launch Preparation (Weeks 19-20)

- Final QA testing
- Security audit
- Load testing
- Documentation (user guides, API docs)
- Soft launch with beta users

---

## Data Requirements

**Initial Seed Data:**

**Games:**

- Minimum 100 popular games across platforms
- Mix of recent releases and classics
- Cover art and screenshots for all games
- Basic metadata (publisher, developer, genres)

**Critic Reviews:**

- Aggregate from major outlets: IGN, GameSpot, Polygon, Kotaku, PC Gamer
- Historical reviews for seeded games

**Publications:**

- 20-30 major gaming publications
- Assign appropriate credibility weights
- Logo images and website links

**Data Sources:**

1. IGDB API - Game metadata and images
2. OpenCritic API - Critic reviews and scores
3. Manual curation - For accuracy and quality

---

## Technical Stack

**Backend:** Ruby on Rails 8.1+, PostgreSQL, Redis, Solid Queue  
**Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS, ViewComponent  
**Storage:** ActiveStorage, CloudFront/CDN  
**Search:** PostgreSQL full-text search (pg_search gem)  
**Auth:** Pundit for authorization  
**Monitoring:** Sentry, New Relic or Scout APM  
**Email:** SendGrid or Postmark

---

## Testing Requirements

**Unit Tests:** Model validations, associations, score algorithms, business logic  
**Integration Tests:** Review submission, moderation, search, authentication  
**System Tests:** Game discovery, review submission, user profiles, admin management  
**Performance Tests:** 1,000 concurrent users, p95 < 2s, error rate < 0.1%  
**Security Tests:** SQL injection, XSS, CSRF, authentication bypass, rate limiting  
**Accessibility Tests:** WCAG 2.1 Level AA compliance with axe-core-rspec

---

## Prerequisites

✅ User authentication (OAuth) - Complete  
✅ Database (PostgreSQL) - Complete  
✅ CI/CD pipeline - Complete  
🔄 Background jobs (Solid Queue) - Phase 1  
🔄 Email service - Phase 1  
🔄 User roles/authorization - Phase 1  
⏳ Design system/UI library  
⏳ Asset CDN

**External APIs:** IGDB, OpenCritic, YouTube

---

## Document Info

**Version:** 1.2  
**Updated:** December 2, 2025  
**Review:** See `docs/review/20251202_game_review_system_analysis.md`  
**Schema:** See `docs/features/20251202_database_schema_design.md`
