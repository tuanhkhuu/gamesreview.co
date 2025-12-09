# Feature: Game Discovery & Search

**Phase:** 2 (Weeks 5-8)  
**Dependencies:** Phase 1 (Game, Platform, Genre models)  
**Status:** Ready for Implementation

---

## User Stories

- **US-1:** I want to browse games by platform so I can find games for my console
- **US-2:** I want to see both critic and user scores so I can make informed purchase decisions
- **US-5:** I want to see gameplay videos and screenshots so I can preview the game

---

## Functional Requirements

### FR-1.2: Game Discovery

- System shall provide search functionality with filters (platform, genre, release date, score)
- System shall display "New Releases" section for games released in the last 30 days
- System shall display "Upcoming Games" section for unreleased titles
- System shall show "Top Rated Games" by metascore and user score
- System shall provide genre-based browsing

### FR-1.3: Game Details Page

- System shall display game title, description, release date, and cover art
- System shall show metascore (critic average) and user score
- System shall list all available platforms with platform-specific scores
- System shall display publisher and developer information
- System shall show rating category (Universal Acclaim, Generally Favorable, etc.)

### FR-8: Search & Discovery

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

---

## UI Specifications

### 1. Home Page

**Hero Section:**

- Featured game carousel (3-5 games)
- Large cover art with title overlay
- Metascore and user score badges
- "View Details" CTA button

**New Releases Carousel:**

- Horizontal scrollable list
- Game cards showing: cover, title, platform icons, metascore
- Released in last 30 days
- "See All" link to New Releases page

**Top Rated Section:**

- Grid layout (3 columns on desktop, 1 on mobile)
- Top 9 games by metascore
- Game cards with cover, title, score, platforms

**Recent User Reviews:**

- List of 5 most recent approved reviews
- Show: game cover, title, user rating, review excerpt (150 chars)
- Link to full review

**Popular Genres:**

- Grid of genre cards with representative images
- Click to browse genre landing page

### 2. Game Detail Page

**Header Section:**

- Game title (H1)
- Cover art (left side, 300x400px)
- Metascore badge (large, color-coded)
- User score badge (large, color-coded)
- Platform icons (all supported platforms)
- Release date
- "Write a Review" button (authenticated users)

**Overview Section:**

- Game description (rich text)
- Publisher name (link to publisher page)
- Developer name (link to developer page)
- Genre tags (clickable, link to genre pages)

**Scores Section:**

- Metascore with rating category label
- Score distribution chart (vertical bar)
- User score with rating category
- User score distribution (positive/mixed/negative %)

**Rating Categories:**

- 90-100: Universal Acclaim (green)
- 75-89: Generally Favorable (light green)
- 50-74: Mixed or Average (yellow)
- 20-49: Generally Unfavorable (orange)
- 0-19: Overwhelming Dislike (red)

### 3. Browse/Search Pages

**Filter Sidebar (left):**

- Platform checkboxes
- Genre checkboxes
- Release date range (date picker)
- Score range sliders (metascore, user score)
- Publisher/Developer search input
- "Clear Filters" button

**Sort Options (top right):**

- Dropdown: Relevance, Release Date (Newest), Release Date (Oldest), Metascore (High to Low), User Score (High to Low), Name (A-Z)

**View Toggle:**

- Grid view (default)
- List view

**Game Cards (Grid View):**

- Cover art image (link to detail page)
- Game title (H3)
- Platform icons (max 4 visible)
- Metascore badge (small)
- User score badge (small)
- Release date (small text)

**Game Cards (List View):**

- Same as grid but horizontal layout
- Includes description excerpt (200 chars)

**Pagination:**

- 24 games per page
- Page numbers with prev/next
- Option: Infinite scroll on mobile

### 4. Browse Pages

**New Releases (`/games/new`):**

- Title: "New Releases"
- Filter: Released in last 30 days
- Default sort: Release Date (Newest)
- Show release date prominently on cards

**Coming Soon (`/games/upcoming`):**

- Title: "Coming Soon"
- Filter: Release date > today
- Default sort: Release Date (Oldest - soonest first)
- Show expected release date on cards

**Top Rated (`/games/top-rated`):**

- Tabs: By Metascore, By User Score, By Platform
- Default sort: Score (High to Low)
- Show rank number on cards (#1, #2, etc.)

**Genre Pages (`/games/genre/:slug`):**

- Title: Genre name (e.g., "Action Games")
- Filter: Genre = selected
- Default sort: Metascore (High to Low)
- Show genre description at top

**Platform Pages (`/games/platform/:slug`):**

- Title: Platform name (e.g., "PlayStation 5 Games")
- Filter: Platform = selected
- Default sort: Release Date (Newest)
- Show platform-specific scores if available

**Publisher/Developer Pages (`/games/publisher/:slug`):**

- Title: Publisher/Developer name
- List all games from that publisher/developer
- Default sort: Release Date (Newest)

---

## Search Implementation

**Technology:**

- PostgreSQL full-text search (pg_search gem)
- Search fields: game title, description
- Ranking by relevance

**Autocomplete:**

- Triggered after 2 characters typed
- Show top 5 matching game titles
- Display: cover thumbnail (small), title, platform icons
- Click to navigate to game detail page

**Search Query Examples:**

```ruby
# Basic search
Game.search_by_title_and_description(params[:q])

# With filters
Game.search_by_title_and_description(params[:q])
    .joins(:platforms).where(platforms: { id: params[:platform_ids] })
    .joins(:genres).where(genres: { id: params[:genre_ids] })
    .where('release_date >= ?', params[:start_date]) if params[:start_date]
    .where('release_date <= ?', params[:end_date]) if params[:end_date]
```

---

## SEO Requirements

**Game Detail Pages:**

- URL: `/games/:slug` (e.g., `/games/elden-ring`)
- Title tag: `{Game Title} - Reviews, Scores & Info | GamesReview`
- Meta description: First 155 chars of game description
- Open Graph tags: og:title, og:description, og:image (cover art), og:type (website)
- Twitter Card tags: twitter:card (summary_large_image), twitter:title, twitter:description, twitter:image
- Schema.org markup: VideoGame type

**Browse Pages:**

- Title tags: `{Category} - GamesReview` (e.g., "New Releases - GamesReview")
- Canonical URLs to prevent duplicate content
- Sitemap.xml generation for all game pages

---

## Performance Requirements

- **NFR-1:** Game detail pages shall load within 2 seconds
- **NFR-2:** Search results shall return within 1 second
- **NFR-4:** Database queries shall use proper indexes for optimization
- **NFR-5:** Frequently accessed data shall be cached (Redis)

**Caching Strategy:**

- Cache game detail pages for 1 hour
- Cache browse pages for 30 minutes
- Cache search results for 15 minutes (per query)
- Invalidate cache when game data updated

**Database Indexes:**

- `games.slug` (unique)
- `games.release_date`
- `games.metascore`
- `games.user_score`
- Full-text search index on `games.title` and `games.description`

---

## Testing Checklist

- [ ] Search returns relevant results
- [ ] Autocomplete works with 2+ characters
- [ ] Filters can be combined (platform + genre + score range)
- [ ] Sort options work correctly
- [ ] Pagination loads correct page
- [ ] Game detail page displays all sections
- [ ] SEO tags present on all pages
- [ ] Mobile responsive layouts
- [ ] Page load times < 2s
- [ ] Cache invalidation works when games updated

---

## Dependencies

**Models Required (from Phase 1):**

- Game
- Platform
- GamePlatform
- Genre
- GameGenre
- Publisher
- Developer

**Gems Required:**

- pg_search - Full-text search
- friendly_id - SEO-friendly slugs
- pagy - Pagination

---

**Next Phase:** Phase 3 - Critic Review System
