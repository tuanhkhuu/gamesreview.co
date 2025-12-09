# Database Schema Design for Game Review System

**Project:** gamesreview.com  
**Date:** December 2, 2025  
**Status:** Planning  
**Type:** Technical Specification

---

## Overview

This document outlines the comprehensive database schema for a game review aggregation platform inspired by Metacritic. The system supports multi-platform games, weighted critic reviews, user-generated reviews with moderation, and rich media content.

### Key Features

- **Multi-Platform Support**: Games can have different scores and release dates per platform
- **Weighted Scoring**: Critic reviews weighted by publication credibility
- **User Reviews**: Community reviews with moderation workflow
- **Review Helpfulness**: Voting system to surface quality reviews
- **Rich Media**: Screenshots and videos per game
- **Performance**: Cached aggregate statistics for fast page loads

---

## Entity Relationship Overview

```
Game (central model)
  ├── has_many GamePlatforms
  │     └── belongs_to Platform
  ├── has_many GameGenres
  │     └── belongs_to Genre
  ├── belongs_to Publisher
  ├── belongs_to Developer
  ├── has_many CriticReviews
  │     └── belongs_to Publication
  ├── has_many UserReviews
  │     ├── belongs_to User
  │     └── has_many ReviewHelpfulnessVotes
  ├── has_many Screenshots
  ├── has_many Videos
  └── has_one GameStats
```

---

## Core Models

### 1. Game

**Purpose**: Central model representing a video game

**Table**: `games`

```ruby
class Game < ApplicationRecord
  # Associations
  belongs_to :publisher
  belongs_to :developer
  has_many :game_platforms, dependent: :destroy
  has_many :platforms, through: :game_platforms
  has_many :game_genres, dependent: :destroy
  has_many :genres, through: :game_genres
  has_many :critic_reviews, dependent: :destroy
  has_many :user_reviews, dependent: :destroy
  has_many :screenshots, dependent: :destroy
  has_many :videos, dependent: :destroy
  has_one :game_stats, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true
  validates :description, presence: true
  validates :release_date, presence: true
  validates :metascore, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100,
    allow_nil: true
  }
  validates :user_score, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 10,
    allow_nil: true
  }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Scopes
  scope :released, -> { where('release_date <= ?', Date.current) }
  scope :upcoming, -> { where('release_date > ?', Date.current) }
  scope :by_metascore, -> { order(metascore: :desc) }
  scope :by_user_score, -> { order(user_score: :desc) }
  scope :recent, -> { order(release_date: :desc) }

  private

  def generate_slug
    self.slug = title.parameterize if title.present?
  end
end
```

**Schema**:

```ruby
create_table :games do |t|
  t.string :title, null: false, limit: 200
  t.string :slug, null: false, index: { unique: true }
  t.text :description, null: false
  t.date :release_date, null: false
  t.string :cover_image_url
  t.references :publisher, null: false, foreign_key: true
  t.references :developer, null: false, foreign_key: true

  # Calculated scores (updated via background jobs)
  t.decimal :metascore, precision: 5, scale: 2 # Weighted critic average (0-100)
  t.decimal :user_score, precision: 4, scale: 2 # User average (0-10)

  # Rating category based on metascore
  t.string :rating_category # Universal Acclaim, Generally Favorable, Mixed, Generally Unfavorable, Overwhelming Dislike

  t.timestamps
end

add_index :games, :release_date
add_index :games, :metascore
add_index :games, :user_score
add_index :games, :created_at
```

**Rating Categories** (based on Metacritic):

- **Universal Acclaim**: 90-100
- **Generally Favorable**: 75-89
- **Mixed or Average**: 50-74
- **Generally Unfavorable**: 20-49
- **Overwhelming Dislike**: 0-19

---

### 2. Platform

**Purpose**: Gaming platforms (PlayStation, Xbox, PC, Nintendo Switch, etc.)

**Table**: `platforms`

```ruby
class Platform < ApplicationRecord
  has_many :game_platforms, dependent: :destroy
  has_many :games, through: :game_platforms

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :platform_type, presence: true, inclusion: {
    in: %w[console pc mobile handheld]
  }

  before_validation :generate_slug, on: :create

  scope :consoles, -> { where(platform_type: 'console') }
  scope :active, -> { where(active: true) }

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
```

**Schema**:

```ruby
create_table :platforms do |t|
  t.string :name, null: false, limit: 100
  t.string :slug, null: false, index: { unique: true }
  t.string :short_name, limit: 20 # e.g., "PS5", "XSX", "PC"
  t.string :platform_type, null: false # console, pc, mobile, handheld
  t.string :manufacturer # Sony, Microsoft, Nintendo, etc.
  t.boolean :active, default: true, null: false
  t.timestamps
end

add_index :platforms, :platform_type
add_index :platforms, :active
```

**Examples**:

- PlayStation 5 (PS5) - console - Sony
- Xbox Series X (XSX) - console - Microsoft
- PC - pc
- Nintendo Switch - handheld - Nintendo

---

### 3. GamePlatform (Join Table)

**Purpose**: Associates games with platforms, storing platform-specific data

**Table**: `game_platforms`

```ruby
class GamePlatform < ApplicationRecord
  belongs_to :game
  belongs_to :platform

  validates :game_id, uniqueness: { scope: :platform_id }
  validates :platform_release_date, presence: true
  validates :platform_metascore, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100,
    allow_nil: true
  }

  scope :released, -> { where('platform_release_date <= ?', Date.current) }
  scope :upcoming, -> { where('platform_release_date > ?', Date.current) }
end
```

**Schema**:

```ruby
create_table :game_platforms do |t|
  t.references :game, null: false, foreign_key: true
  t.references :platform, null: false, foreign_key: true
  t.date :platform_release_date, null: false
  t.decimal :platform_metascore, precision: 5, scale: 2
  t.decimal :platform_user_score, precision: 4, scale: 2
  t.text :platform_notes # Platform-specific features or differences
  t.timestamps
end

add_index :game_platforms, [:game_id, :platform_id], unique: true
add_index :game_platforms, :platform_release_date
```

**Why**: Some games have different scores per platform (e.g., Cyberpunk 2077 scored higher on PC than consoles due to performance issues)

---

### 4. Genre

**Purpose**: Game categories/types

**Table**: `genres`

```ruby
class Genre < ApplicationRecord
  has_many :game_genres, dependent: :destroy
  has_many :games, through: :game_genres

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
```

**Schema**:

```ruby
create_table :genres do |t|
  t.string :name, null: false, limit: 100
  t.string :slug, null: false, index: { unique: true }
  t.text :description
  t.timestamps
end
```

**Examples**:

- Action, Adventure, RPG, Strategy, Sports, Racing, Puzzle, Simulation, Fighting, Platformer, Shooter

---

### 5. GameGenre (Join Table)

**Purpose**: Many-to-many relationship between games and genres

**Table**: `game_genres`

```ruby
class GameGenre < ApplicationRecord
  belongs_to :game
  belongs_to :genre

  validates :game_id, uniqueness: { scope: :genre_id }
  validates :genre_type, inclusion: { in: %w[primary secondary] }
end
```

**Schema**:

```ruby
create_table :game_genres do |t|
  t.references :game, null: false, foreign_key: true
  t.references :genre, null: false, foreign_key: true
  t.string :genre_type, default: 'secondary' # primary or secondary
  t.timestamps
end

add_index :game_genres, [:game_id, :genre_id], unique: true
```

**Why**: Games often span multiple genres (e.g., "Action RPG", "Tactical Shooter")

---

### 6. Publisher

**Purpose**: Game publishers

**Table**: `publishers`

```ruby
class Publisher < ApplicationRecord
  has_many :games, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
```

**Schema**:

```ruby
create_table :publishers do |t|
  t.string :name, null: false, limit: 200
  t.string :slug, null: false, index: { unique: true }
  t.string :website_url
  t.string :country
  t.text :description
  t.timestamps
end
```

**Examples**:

- Electronic Arts, Activision Blizzard, Sony Interactive Entertainment, Nintendo, Bandai Namco

---

### 7. Developer

**Purpose**: Game development studios

**Table**: `developers`

```ruby
class Developer < ApplicationRecord
  has_many :games, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
```

**Schema**:

```ruby
create_table :developers do |t|
  t.string :name, null: false, limit: 200
  t.string :slug, null: false, index: { unique: true }
  t.string :website_url
  t.string :country
  t.text :description
  t.timestamps
end
```

**Examples**:

- FromSoftware, Naughty Dog, CD Projekt Red, Rockstar Games, Valve

---

## Review Models

### 8. Publication

**Purpose**: Gaming media outlets that publish professional reviews

**Table**: `publications`

```ruby
class Publication < ApplicationRecord
  has_many :critic_reviews, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :credibility_weight, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 10
  }

  before_validation :generate_slug, on: :create

  scope :high_credibility, -> { where('credibility_weight >= ?', 8) }
  scope :active, -> { where(active: true) }

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
```

**Schema**:

```ruby
create_table :publications do |t|
  t.string :name, null: false, limit: 200
  t.string :slug, null: false, index: { unique: true }
  t.string :website_url
  t.string :logo_url
  t.integer :credibility_weight, default: 5, null: false # 1-10 scale
  t.boolean :active, default: true, null: false
  t.text :description
  t.timestamps
end

add_index :publications, :credibility_weight
add_index :publications, :active
```

**Credibility Weight** (affects metascore calculation):

- **10**: Major outlets (IGN, GameSpot, Polygon, Edge Magazine)
- **7-9**: Established sites (Destructoid, Kotaku, PC Gamer, GamesRadar)
- **4-6**: Smaller publications, regional sites
- **1-3**: Blogs, new outlets

---

### 9. CriticReview

**Purpose**: Professional critic reviews from gaming publications

**Table**: `critic_reviews`

```ruby
class CriticReview < ApplicationRecord
  belongs_to :game
  belongs_to :publication
  belongs_to :platform, optional: true

  validates :game_id, uniqueness: { scope: [:publication_id, :platform_id] }
  validates :score, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
  validates :review_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  after_save :update_game_metascore
  after_destroy :update_game_metascore

  scope :recent, -> { order(published_at: :desc) }
  scope :for_platform, ->(platform) { where(platform: platform) }

  private

  def update_game_metascore
    UpdateGameMetascoreJob.perform_later(game_id)
  end
end
```

**Schema**:

```ruby
create_table :critic_reviews do |t|
  t.references :game, null: false, foreign_key: true
  t.references :publication, null: false, foreign_key: true
  t.references :platform, foreign_key: true # Platform-specific review
  t.integer :score, null: false # 0-100 scale
  t.text :excerpt, limit: 1000 # Short excerpt from review
  t.string :review_url, null: false
  t.string :author_name
  t.date :published_at
  t.timestamps
end

add_index :critic_reviews, [:game_id, :publication_id, :platform_id],
  unique: true, name: 'index_critic_reviews_uniqueness'
add_index :critic_reviews, :published_at
add_index :critic_reviews, :score
```

**Metascore Calculation**:

```ruby
# app/services/metascore_calculator_service.rb
class MetascoreCalculatorService
  def initialize(game)
    @game = game
  end

  def calculate
    reviews = @game.critic_reviews.includes(:publication)
    return nil if reviews.empty?

    total_weighted_score = 0
    total_weight = 0

    reviews.each do |review|
      weight = review.publication.credibility_weight
      total_weighted_score += (review.score * weight)
      total_weight += weight
    end

    (total_weighted_score / total_weight.to_f).round(2)
  end
end
```

---

### 10. UserReview

**Purpose**: User-submitted game reviews

**Table**: `user_reviews`

```ruby
class UserReview < ApplicationRecord
  belongs_to :game
  belongs_to :user
  belongs_to :platform
  has_many :review_helpfulness_votes, dependent: :destroy

  validates :game_id, uniqueness: { scope: [:user_id, :platform_id] }
  validates :score, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 10
  }
  validates :body, presence: true, length: { minimum: 75, maximum: 10000 }
  validates :title, length: { maximum: 100 }
  validates :completion_status, inclusion: {
    in: %w[playing completed dropped]
  }
  validates :moderation_status, inclusion: {
    in: %w[pending approved rejected flagged]
  }

  after_save :update_game_user_score, if: :approved?
  after_destroy :update_game_user_score

  scope :approved, -> { where(moderation_status: 'approved') }
  scope :pending, -> { where(moderation_status: 'pending') }
  scope :flagged, -> { where(moderation_status: 'flagged') }
  scope :by_helpfulness, -> { order(helpful_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :positive, -> { where('score >= ?', 7) }
  scope :mixed, -> { where(score: 4..6) }
  scope :negative, -> { where('score <= ?', 3) }

  def approved?
    moderation_status == 'approved'
  end

  private

  def update_game_user_score
    UpdateGameUserScoreJob.perform_later(game_id)
  end
end
```

**Schema**:

```ruby
create_table :user_reviews do |t|
  t.references :game, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.references :platform, null: false, foreign_key: true

  t.string :title, limit: 100
  t.text :body, null: false
  t.integer :score, null: false # 0-10 scale

  # Metadata
  t.string :completion_status # playing, completed, dropped
  t.integer :hours_played
  t.integer :difficulty_rating # 1-5 scale
  t.boolean :contains_spoilers, default: false, null: false

  # Moderation
  t.string :moderation_status, default: 'pending', null: false
  t.text :moderation_notes # Internal notes for moderators
  t.datetime :approved_at
  t.references :approved_by, foreign_key: { to_table: :users }

  # Helpfulness (cached from votes)
  t.integer :helpful_count, default: 0, null: false
  t.integer :unhelpful_count, default: 0, null: false

  t.timestamps
end

add_index :user_reviews, [:game_id, :user_id, :platform_id],
  unique: true, name: 'index_user_reviews_uniqueness'
add_index :user_reviews, :moderation_status
add_index :user_reviews, :created_at
add_index :user_reviews, :score
add_index :user_reviews, :helpful_count
```

**User Score Calculation**:

```ruby
# app/services/user_score_calculator_service.rb
class UserScoreCalculatorService
  def initialize(game)
    @game = game
  end

  def calculate
    approved_reviews = @game.user_reviews.approved
    return nil if approved_reviews.empty?

    total_score = approved_reviews.sum(:score)
    (total_score / approved_reviews.count.to_f).round(2)
  end
end
```

**Moderation Workflow**:

- New reviews start as `pending`
- Moderators can `approve`, `reject`, or `flag` reviews
- Auto-approve for users with good reputation (configurable threshold)
- Auto-flag reviews with 5+ user reports

---

### 11. ReviewHelpfulnessVote

**Purpose**: Allows users to vote on review helpfulness

**Table**: `review_helpfulness_votes`

```ruby
class ReviewHelpfulnessVote < ApplicationRecord
  belongs_to :user_review, counter_cache: true
  belongs_to :user

  validates :user_review_id, uniqueness: { scope: :user_id }
  validates :vote_type, inclusion: { in: %w[helpful unhelpful] }

  after_create :update_review_counters
  after_update :update_review_counters
  after_destroy :update_review_counters

  scope :helpful, -> { where(vote_type: 'helpful') }
  scope :unhelpful, -> { where(vote_type: 'unhelpful') }

  private

  def update_review_counters
    user_review.update_columns(
      helpful_count: user_review.review_helpfulness_votes.helpful.count,
      unhelpful_count: user_review.review_helpfulness_votes.unhelpful.count
    )
  end
end
```

**Schema**:

```ruby
create_table :review_helpfulness_votes do |t|
  t.references :user_review, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.string :vote_type, null: false # helpful or unhelpful
  t.timestamps
end

add_index :review_helpfulness_votes, [:user_review_id, :user_id],
  unique: true, name: 'index_helpfulness_votes_uniqueness'
add_index :review_helpfulness_votes, :vote_type
```

---

## Media Models

### 12. Screenshot

**Purpose**: Game screenshots for galleries

**Table**: `screenshots`

```ruby
class Screenshot < ApplicationRecord
  belongs_to :game
  belongs_to :platform, optional: true

  validates :image_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :display_order, numericality: { greater_than_or_equal_to: 0 }

  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(display_order: :asc, created_at: :asc) }
end
```

**Schema**:

```ruby
create_table :screenshots do |t|
  t.references :game, null: false, foreign_key: true
  t.references :platform, foreign_key: true # Platform-specific screenshot
  t.string :image_url, null: false
  t.string :thumbnail_url
  t.string :caption
  t.integer :display_order, default: 0, null: false
  t.boolean :featured, default: false, null: false
  t.timestamps
end

add_index :screenshots, [:game_id, :display_order]
add_index :screenshots, :featured
```

---

### 13. Video

**Purpose**: Game trailers and gameplay videos

**Table**: `videos`

```ruby
class Video < ApplicationRecord
  belongs_to :game

  validates :video_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :video_type, inclusion: {
    in: %w[trailer gameplay review developer_diary]
  }
  validates :display_order, numericality: { greater_than_or_equal_to: 0 }

  scope :trailers, -> { where(video_type: 'trailer') }
  scope :gameplay, -> { where(video_type: 'gameplay') }
  scope :ordered, -> { order(display_order: :asc, created_at: :desc) }
end
```

**Schema**:

```ruby
create_table :videos do |t|
  t.references :game, null: false, foreign_key: true
  t.string :title, null: false, limit: 200
  t.text :description
  t.string :video_url, null: false # YouTube/Vimeo embed URL
  t.string :thumbnail_url
  t.string :video_type, null: false # trailer, gameplay, review, developer_diary
  t.integer :duration_seconds
  t.integer :display_order, default: 0, null: false
  t.date :published_at
  t.timestamps
end

add_index :videos, [:game_id, :video_type]
add_index :videos, [:game_id, :display_order]
```

---

## Aggregation Model

### 14. GameStats

**Purpose**: Cached aggregate statistics for performance

**Table**: `game_stats`

```ruby
class GameStats < ApplicationRecord
  belongs_to :game

  validates :game_id, uniqueness: true

  # Updated via background jobs
  def refresh!
    update!(
      total_critic_reviews: game.critic_reviews.count,
      total_user_reviews: game.user_reviews.approved.count,
      positive_user_reviews: game.user_reviews.approved.positive.count,
      mixed_user_reviews: game.user_reviews.approved.mixed.count,
      negative_user_reviews: game.user_reviews.approved.negative.count,
      average_playtime_hours: game.user_reviews.approved.average(:hours_played).to_f.round(1),
      average_difficulty: game.user_reviews.approved.average(:difficulty_rating).to_f.round(1),
      completion_rate: calculate_completion_rate,
      updated_at: Time.current
    )
  end

  private

  def calculate_completion_rate
    total = game.user_reviews.approved.count
    return 0 if total.zero?

    completed = game.user_reviews.approved.where(completion_status: 'completed').count
    ((completed / total.to_f) * 100).round(1)
  end
end
```

**Schema**:

```ruby
create_table :game_stats do |t|
  t.references :game, null: false, foreign_key: true, index: { unique: true }

  # Review counts
  t.integer :total_critic_reviews, default: 0, null: false
  t.integer :total_user_reviews, default: 0, null: false
  t.integer :positive_user_reviews, default: 0, null: false
  t.integer :mixed_user_reviews, default: 0, null: false
  t.integer :negative_user_reviews, default: 0, null: false

  # Aggregated metadata
  t.decimal :average_playtime_hours, precision: 5, scale: 1
  t.decimal :average_difficulty, precision: 3, scale: 1 # 1.0 - 5.0
  t.decimal :completion_rate, precision: 5, scale: 2 # Percentage

  t.timestamps
end
```

**Why**: Aggregating statistics on-the-fly is expensive. Cache them and update via background jobs.

---

## Background Jobs

### UpdateGameMetascoreJob

```ruby
class UpdateGameMetascoreJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = Game.find(game_id)
    metascore = MetascoreCalculatorService.new(game).calculate

    rating_category = case metascore
    when 90..100 then 'Universal Acclaim'
    when 75..89 then 'Generally Favorable'
    when 50..74 then 'Mixed or Average'
    when 20..49 then 'Generally Unfavorable'
    when 0..19 then 'Overwhelming Dislike'
    end

    game.update_columns(metascore: metascore, rating_category: rating_category)

    # Also update platform-specific scores
    game.game_platforms.each do |gp|
      platform_metascore = calculate_platform_metascore(game, gp.platform)
      gp.update_column(:platform_metascore, platform_metascore)
    end
  end

  private

  def calculate_platform_metascore(game, platform)
    reviews = game.critic_reviews.for_platform(platform).includes(:publication)
    return nil if reviews.empty?

    total_weighted_score = 0
    total_weight = 0

    reviews.each do |review|
      weight = review.publication.credibility_weight
      total_weighted_score += (review.score * weight)
      total_weight += weight
    end

    (total_weighted_score / total_weight.to_f).round(2)
  end
end
```

### UpdateGameUserScoreJob

```ruby
class UpdateGameUserScoreJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = Game.find(game_id)
    user_score = UserScoreCalculatorService.new(game).calculate
    game.update_column(:user_score, user_score)

    # Update platform-specific user scores
    game.game_platforms.each do |gp|
      platform_reviews = game.user_reviews.approved.where(platform: gp.platform)
      next if platform_reviews.empty?

      platform_user_score = (platform_reviews.sum(:score) / platform_reviews.count.to_f).round(2)
      gp.update_column(:platform_user_score, platform_user_score)
    end

    # Refresh stats
    game.game_stats&.refresh!
  end
end
```

### RefreshGameStatsJob

```ruby
class RefreshGameStatsJob < ApplicationJob
  queue_as :low_priority

  def perform(game_id)
    game = Game.find(game_id)
    stats = game.game_stats || game.create_game_stats!
    stats.refresh!
  end
end
```

---

## Database Indexes Summary

**Critical Indexes** (for performance):

```ruby
# Games
add_index :games, :slug, unique: true
add_index :games, :release_date
add_index :games, :metascore
add_index :games, :user_score
add_index :games, :created_at

# Platforms
add_index :platforms, :slug, unique: true
add_index :platforms, :platform_type
add_index :platforms, :active

# GamePlatforms
add_index :game_platforms, [:game_id, :platform_id], unique: true
add_index :game_platforms, :platform_release_date

# Genres
add_index :genres, :slug, unique: true

# GameGenres
add_index :game_genres, [:game_id, :genre_id], unique: true

# Publishers & Developers
add_index :publishers, :slug, unique: true
add_index :developers, :slug, unique: true

# Publications
add_index :publications, :slug, unique: true
add_index :publications, :credibility_weight
add_index :publications, :active

# CriticReviews
add_index :critic_reviews, [:game_id, :publication_id, :platform_id], unique: true
add_index :critic_reviews, :published_at
add_index :critic_reviews, :score

# UserReviews
add_index :user_reviews, [:game_id, :user_id, :platform_id], unique: true
add_index :user_reviews, :moderation_status
add_index :user_reviews, :created_at
add_index :user_reviews, :score
add_index :user_reviews, :helpful_count

# ReviewHelpfulnessVotes
add_index :review_helpfulness_votes, [:user_review_id, :user_id], unique: true

# Screenshots
add_index :screenshots, [:game_id, :display_order]
add_index :screenshots, :featured

# Videos
add_index :videos, [:game_id, :video_type]
add_index :videos, [:game_id, :display_order]

# GameStats
add_index :game_stats, :game_id, unique: true
```

---

## Sample Queries

### Find Top Rated Games by Platform

```ruby
# All PS5 games sorted by metascore
Game.joins(:game_platforms)
    .where(game_platforms: { platform_id: ps5.id })
    .where('game_platforms.platform_metascore IS NOT NULL')
    .order('game_platforms.platform_metascore DESC')
    .limit(10)
```

### Find Recent Games by Genre

```ruby
# Recent Action RPG games
Game.joins(:genres)
    .where(genres: { slug: 'action-rpg' })
    .where('release_date >= ?', 30.days.ago)
    .order(release_date: :desc)
```

### Get Game with All Related Data (avoiding N+1)

```ruby
Game.includes(
  :publisher,
  :developer,
  :platforms,
  :genres,
  critic_reviews: :publication,
  user_reviews: [:user, :platform],
  :screenshots,
  :videos,
  :game_stats
).find_by(slug: 'elden-ring')
```

### Find Most Helpful Reviews for a Game

```ruby
game.user_reviews.approved
    .by_helpfulness
    .limit(10)
```

### Calculate Review Distribution

```ruby
stats = game.user_reviews.approved.group(:score).count
# => {10 => 523, 9 => 412, 8 => 301, ...}

positive = game.user_reviews.approved.positive.count
mixed = game.user_reviews.approved.mixed.count
negative = game.user_reviews.approved.negative.count

total = positive + mixed + negative
{
  positive_percentage: (positive / total.to_f * 100).round(1),
  mixed_percentage: (mixed / total.to_f * 100).round(1),
  negative_percentage: (negative / total.to_f * 100).round(1)
}
```

---

## Data Validation & Constraints

### Database-Level Constraints

```ruby
# Ensure data integrity at the database level
create_table :games do |t|
  # NOT NULL constraints
  t.string :title, null: false
  t.string :slug, null: false
  t.date :release_date, null: false

  # FOREIGN KEY constraints
  t.references :publisher, null: false, foreign_key: true
  t.references :developer, null: false, foreign_key: true
end

# UNIQUE constraints
add_index :games, :slug, unique: true
add_index :user_reviews, [:game_id, :user_id, :platform_id], unique: true

# CHECK constraints (PostgreSQL)
execute <<-SQL
  ALTER TABLE games ADD CONSTRAINT check_metascore_range
  CHECK (metascore IS NULL OR (metascore >= 0 AND metascore <= 100));
SQL

execute <<-SQL
  ALTER TABLE user_reviews ADD CONSTRAINT check_score_range
  CHECK (score >= 0 AND score <= 10);
SQL
```

### Model-Level Validations

All critical validations should exist at BOTH the model and database level for defense in depth.

---

## Security Considerations

### 1. Review Spam Prevention

```ruby
# Rate limiting (using Rack::Attack)
throttle('reviews/user', limit: 5, period: 24.hours) do |req|
  req.env['warden'].user&.id if req.path == '/reviews' && req.post?
end

# Model validation
class UserReview < ApplicationRecord
  validate :daily_review_limit

  private

  def daily_review_limit
    return unless user

    today_count = user.user_reviews.where('created_at >= ?', 24.hours.ago).count
    if today_count >= 5
      errors.add(:base, 'You have reached the daily review limit')
    end
  end
end
```

### 2. Input Sanitization

```ruby
# Sanitize HTML in review bodies
class UserReview < ApplicationRecord
  before_save :sanitize_body

  private

  def sanitize_body
    self.body = ActionController::Base.helpers.sanitize(
      body,
      tags: [], # Strip all HTML
      attributes: []
    )
  end
end
```

### 3. Authorization

```ruby
# app/policies/user_review_policy.rb (using Pundit)
class UserReviewPolicy < ApplicationPolicy
  def create?
    user.present? && user.verified_email?
  end

  def update?
    user.present? && (record.user == user || user.admin?)
  end

  def destroy?
    user.present? && (record.user == user || user.moderator? || user.admin?)
  end

  def moderate?
    user.present? && (user.moderator? || user.admin?)
  end
end
```

---

## Caching Strategy

### Fragment Caching

```erb
<%# app/views/games/show.html.erb %>
<% cache ['game-details', @game] do %>
  <%= render 'game_details', game: @game %>
<% end %>

<% cache ['critic-reviews', @game, @game.critic_reviews.maximum(:updated_at)] do %>
  <%= render 'critic_reviews', game: @game %>
<% end %>

<% cache ['user-reviews', @game, @game.user_reviews.approved.maximum(:updated_at)] do %>
  <%= render 'user_reviews', game: @game %>
<% end %>
```

### Low-Level Caching

```ruby
class Game < ApplicationRecord
  def average_rating
    Rails.cache.fetch("game:#{id}:average_rating", expires_in: 1.hour) do
      user_reviews.approved.average(:score).to_f.round(2)
    end
  end

  def top_reviews
    Rails.cache.fetch("game:#{id}:top_reviews", expires_in: 30.minutes) do
      user_reviews.approved.by_helpfulness.limit(5).to_a
    end
  end
end
```

### Cache Invalidation

```ruby
class UserReview < ApplicationRecord
  after_commit :clear_caches

  private

  def clear_caches
    Rails.cache.delete("game:#{game_id}:average_rating")
    Rails.cache.delete("game:#{game_id}:top_reviews")
  end
end
```

---

## Migration Order

When creating migrations, follow this dependency order:

1. **Base entities** (no foreign keys):

   - `publishers`
   - `developers`
   - `platforms`
   - `genres`
   - `publications`

2. **Main entity**:

   - `games` (references publishers, developers)

3. **Association tables**:

   - `game_platforms` (references games, platforms)
   - `game_genres` (references games, genres)

4. **Review tables**:

   - `critic_reviews` (references games, publications, platforms)
   - `user_reviews` (references games, users, platforms)
   - `review_helpfulness_votes` (references user_reviews, users)

5. **Media tables**:

   - `screenshots` (references games, platforms)
   - `videos` (references games)

6. **Stats table**:
   - `game_stats` (references games)

---

## Future Enhancements

### Phase 2 Features

1. **User Lists**: Users can create custom game lists (favorites, wishlist, backlog)
2. **Game Recommendations**: ML-based recommendations from user reviews and ratings
3. **Social Features**: Follow users, activity feeds, review comments
4. **Advanced Search**: Elasticsearch integration for complex queries
5. **API**: Public REST/GraphQL API for third-party integrations
6. **User Achievements**: Badges for reviewing milestones
7. **Editorial Content**: News articles, guides, developer interviews
8. **Deals & Pricing**: Track game prices across stores
9. **Community Forums**: Discussion boards per game
10. **Live Streams**: Integrate Twitch/YouTube live gameplay

### Additional Tables for Future

```ruby
# User game lists
create_table :user_game_lists
create_table :user_game_list_items

# Review comments
create_table :review_comments

# User follows
create_table :user_follows

# Price tracking
create_table :game_prices

# News articles
create_table :articles
```

---

## Conclusion

This schema provides a solid foundation for a comprehensive game review platform with:

- ✅ Multi-platform support with platform-specific data
- ✅ Weighted critic scoring system
- ✅ User-generated content with moderation
- ✅ Community engagement (helpfulness voting)
- ✅ Rich media support (screenshots, videos)
- ✅ Performance optimization (caching, indexes, background jobs)
- ✅ Data integrity (constraints, validations)
- ✅ Scalability (efficient queries, aggregations)
- ✅ Security (authorization, input sanitization, rate limiting)

The design follows Rails conventions and best practices while providing flexibility for future enhancements.

---

**Next Steps**:

1. Create migrations in dependency order
2. Generate model files with associations and validations
3. Implement background jobs for score calculations
4. Create seed data for testing
5. Build admin interface for game/review management
6. Develop public-facing views for browsing and reviewing games
