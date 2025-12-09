# Feature: Critic Review System

**Phase:** 3 (Weeks 9-10)  
**Dependencies:** Phase 1 (Game, Publication, CriticReview models) + Phase 2 (Game detail pages)  
**Status:** Ready for Implementation

---

## User Stories

- **US-2:** I want to see both critic and user scores so I can make informed purchase decisions
- **US-3:** I want to read detailed reviews with pros/cons so I understand game quality

---

## Functional Requirements

### FR-2: Critic Review System

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

---

## Database Schema

### Publication Model

```ruby
class Publication < ApplicationRecord
  has_many :critic_reviews
  has_many :games, through: :critic_reviews

  has_one_attached :logo

  validates :name, presence: true, uniqueness: true
  validates :website_url, presence: true, format: { with: URI::regexp(%w[http https]) }
  validates :weight, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 10
  }

  scope :major_outlets, -> { where('weight >= ?', 8) }
  scope :by_weight, -> { order(weight: :desc) }
end
```

### CriticReview Model

```ruby
class CriticReview < ApplicationRecord
  belongs_to :game
  belongs_to :publication
  belongs_to :platform, optional: true

  validates :score, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
  validates :review_url, presence: true, format: { with: URI::regexp(%w[http https]) }
  validates :excerpt, length: { maximum: 500 }
  validates :author, presence: true
  validates :published_at, presence: true

  scope :ordered_by_weight, -> { joins(:publication).order('publications.weight DESC, published_at DESC') }
  scope :for_platform, ->(platform_id) { where(platform_id: platform_id) }

  after_save :update_game_metascore
  after_destroy :update_game_metascore

  private

  def update_game_metascore
    UpdateMetascoreJob.perform_later(game.id)
  end
end
```

### Game Model (Metascore)

```ruby
class Game < ApplicationRecord
  has_many :critic_reviews
  has_many :publications, through: :critic_reviews

  # Metascore is cached on the game record
  validates :metascore, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100,
    allow_nil: true
  }

  def calculate_metascore
    reviews = critic_reviews.includes(:publication)
    return nil if reviews.empty?

    total_weighted_score = 0
    total_weight = 0

    reviews.each do |review|
      weight = review.publication.weight
      total_weighted_score += review.score * weight
      total_weight += weight
    end

    (total_weighted_score.to_f / total_weight).round
  end

  def rating_category
    return 'No Reviews' if metascore.nil?

    case metascore
    when 90..100
      'Universal Acclaim'
    when 75..89
      'Generally Favorable'
    when 50..74
      'Mixed or Average'
    when 20..49
      'Generally Unfavorable'
    when 0..19
      'Overwhelming Dislike'
    end
  end

  def rating_color
    return 'gray' if metascore.nil?

    case metascore
    when 90..100 then 'green'
    when 75..89 then 'light-green'
    when 50..74 then 'yellow'
    when 20..49 then 'orange'
    when 0..19 then 'red'
    end
  end
end
```

---

## Metascore Calculation Algorithm

### Weighted Average Formula

```
Metascore = Σ(Review Score × Publication Weight) / Σ(Publication Weight)
```

### Example Calculation

```
Game has 3 critic reviews:
- IGN (weight 10): 85
- GameSpot (weight 10): 90
- IndieGamerBlog (weight 3): 70

Metascore = (85×10 + 90×10 + 70×3) / (10 + 10 + 3)
          = (850 + 900 + 210) / 23
          = 1960 / 23
          = 85.2 → rounds to 85
```

### Background Job

```ruby
class UpdateMetascoreJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = Game.find(game_id)
    new_metascore = game.calculate_metascore

    game.update_column(:metascore, new_metascore)
    game.update_column(:metascore_updated_at, Time.current)

    # Invalidate cache
    Rails.cache.delete("game_#{game.id}_detail")
  end
end
```

---

## Publication Weight Guidelines

### Weight 10 (Major Outlets)

- IGN
- GameSpot
- Polygon
- Kotaku
- PC Gamer
- Eurogamer
- GamesRadar+

### Weight 7-9 (Established Sites)

- Destructoid
- Giant Bomb
- Game Informer
- Rock Paper Shotgun
- VG247
- US Gamer
- Push Square

### Weight 4-6 (Smaller Publications)

- Indie game focused sites
- Regional publications
- Specialized genre sites
- Gaming sections of mainstream media

### Weight 1-3 (Blogs & Niche)

- Personal blogs
- YouTube review channels
- Small community sites

---

## UI Specifications

### Metascore Badge (Game Detail Page)

**Large Badge:**

- Circular or square design
- Score number (large font, 48px)
- Rating category below (e.g., "Universal Acclaim")
- Color-coded background:
  - Green (90-100)
  - Light green (75-89)
  - Yellow (50-74)
  - Orange (20-49)
  - Red (0-19)
- Review count below (e.g., "Based on 23 critic reviews")

### Critic Reviews Section

**Section Header:**

- "Critic Reviews" title
- Filter by platform (dropdown if applicable)
- "See All Reviews" link (if > 10 reviews)

**Review List:**

- Show top 10 reviews by default
- Sorted by publication weight, then date

**Review Card:**

- Publication logo (40x40px, left)
- Publication name (bold)
- Review score badge (right, color-coded)
- Author name and date (small text)
- Review excerpt (max 500 chars, truncated with "...")
- "Read Full Review" link (opens in new tab)

**Example Layout:**

```
┌─────────────────────────────────────────────┐
│ [Logo] IGN                          [95]    │
│        by Ryan McCaffrey              🟢    │
│        November 15, 2024                    │
│                                             │
│ "An absolute masterpiece that redefines    │
│  the genre with innovative gameplay and     │
│  stunning visuals..."                       │
│                                             │
│ Read Full Review →                          │
└─────────────────────────────────────────────┘
```

---

## Admin Interface

### Publication Management

**List View:**

- Table showing: Logo, Name, Website, Weight, Review Count
- Sort by: Name, Weight, Review Count
- Filter by weight range
- "Add Publication" button

**Form Fields:**

- Name (required)
- Website URL (required)
- Weight (1-10, required)
- Logo upload (optional, 200x200px)
- Description (optional, rich text)

### Critic Review Management

**List View:**

- Table showing: Game, Publication, Score, Author, Date
- Filter by: Game, Publication, Platform, Score range
- Sort by: Date, Score, Weight
- "Add Review" button

**Form Fields:**

- Game (select dropdown with search)
- Publication (select dropdown)
- Platform (optional, if review is platform-specific)
- Score (0-100, required)
- Author (required)
- Published date (required, date picker)
- Review URL (required)
- Excerpt (textarea, max 500 chars)

**Validation:**

- Check for duplicate reviews (same game + publication + platform)
- Validate score is 0-100
- Validate URL is valid and accessible

---

## Data Aggregation

### Initial Seeding

**Publications to Add:**

1. IGN (weight: 10)
2. GameSpot (weight: 10)
3. Polygon (weight: 10)
4. Kotaku (weight: 10)
5. PC Gamer (weight: 10)
6. Eurogamer (weight: 9)
7. GamesRadar+ (weight: 9)
8. Destructoid (weight: 8)
9. Giant Bomb (weight: 8)
10. Game Informer (weight: 8)

**Data Sources:**

- OpenCritic API (critic reviews and scores)
- Manual scraping from publication websites
- RSS feeds from gaming sites

### OpenCritic API Integration

```ruby
class OpencriticService
  BASE_URL = 'https://api.opencritic.com/api'

  def fetch_game_reviews(game_name)
    # Search for game
    response = HTTParty.get("#{BASE_URL}/game/search?criteria=#{game_name}")
    game_data = JSON.parse(response.body).first

    return [] unless game_data

    # Fetch reviews for game
    game_id = game_data['id']
    reviews_response = HTTParty.get("#{BASE_URL}/review/game/#{game_id}")
    JSON.parse(reviews_response.body)
  end

  def import_reviews_for_game(game)
    reviews_data = fetch_game_reviews(game.title)

    reviews_data.each do |review_data|
      publication = Publication.find_or_create_by(name: review_data['outlet'])

      CriticReview.create(
        game: game,
        publication: publication,
        score: review_data['score'],
        author: review_data['author'],
        published_at: review_data['publishedDate'],
        review_url: review_data['externalUrl'],
        excerpt: review_data['snippet']
      )
    end

    UpdateMetascoreJob.perform_later(game.id)
  end
end
```

---

## Testing Checklist

- [ ] Create publications with different weights
- [ ] Add critic reviews for a game
- [ ] Metascore calculates correctly (weighted average)
- [ ] Rating category displays based on score
- [ ] Rating color matches score range
- [ ] Reviews sorted by publication weight
- [ ] Review excerpts truncated at 500 chars
- [ ] Links to full reviews open in new tab
- [ ] Admin can add/edit/delete publications
- [ ] Admin can add/edit/delete reviews
- [ ] Duplicate review validation works
- [ ] Metascore updates when review added/deleted
- [ ] Background job processes correctly
- [ ] Cache invalidates on metascore update

---

**Next Phase:** Phase 4 - User Review System
