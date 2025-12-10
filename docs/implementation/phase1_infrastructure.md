# Phase 1 Foundation: Database Models, Background Jobs & Email Service

## Overview

This document describes the complete Phase 1 foundation implementation including:

- Database schema and migrations
- Core domain models with associations and validations
- Authorization policies (Pundit)
- Background job infrastructure (Solid Queue)
- Email service configuration

## Database Models & Migrations

### Core Domain Models

Phase 1 implements 10 core models representing the game review platform's domain:

#### 1. Publisher

**File:** `app/models/publisher.rb`  
**Migration:** `db/migrate/20251209162126_create_publishers.rb`

Represents game publishing companies.

**Attributes:**

- `name` (string, required, unique)
- `slug` (string, unique, indexed) - Auto-generated from name
- `description` (text, optional)
- `website_url` (string, optional)

**Associations:**

- `has_many :games`

**Validations:**

- Name: presence, uniqueness
- Slug: presence, uniqueness, auto-generated

**Scopes:**

- `alphabetical` - Orders publishers by name

**Example:**

```ruby
publisher = Publisher.create!(
  name: "Nintendo",
  description: "Japanese gaming company",
  website_url: "https://www.nintendo.com"
)
```

#### 2. Developer

**File:** `app/models/developer.rb`  
**Migration:** `db/migrate/20251209170425_create_developers.rb`

Represents game development studios.

**Attributes:**

- `name` (string, required, unique)
- `slug` (string, unique, indexed)
- `description` (text, optional)
- `website_url` (string, optional)

**Associations:**

- `has_many :games`

**Validations:**

- Name: presence, uniqueness
- Slug: presence, uniqueness, auto-generated

**Example:**

```ruby
developer = Developer.create!(
  name: "FromSoftware",
  description: "Developer of Dark Souls series"
)
```

#### 3. Platform

**File:** `app/models/platform.rb`  
**Migration:** `db/migrate/20251209170529_create_platforms.rb`

Represents gaming platforms (consoles, PC, mobile).

**Attributes:**

- `name` (string, required, unique)
- `platform_type` (enum, required) - console/pc/mobile/handheld/arcade
- `manufacturer` (string, optional)
- `release_year` (integer, optional)
- `active` (boolean, default: true)

**Associations:**

- `has_many :game_platforms`
- `has_many :games, through: :game_platforms`
- `has_many :critic_reviews`
- `has_many :user_reviews`

**Enums:**

- `platform_type`: console, pc, mobile, handheld, arcade

**Scopes:**

- `active` - Only active platforms

**Example:**

```ruby
platform = Platform.create!(
  name: "PlayStation 5",
  platform_type: :console,
  manufacturer: "Sony",
  release_year: 2020
)
```

#### 4. Genre

**File:** `app/models/genre.rb`  
**Migration:** `db/migrate/20251209170611_create_genres.rb`

Represents game genres.

**Attributes:**

- `name` (string, required, unique)
- `description` (text, optional)

**Associations:**

- `has_many :game_genres`
- `has_many :games, through: :game_genres`

**Validations:**

- Name: presence, uniqueness

**Example:**

```ruby
genre = Genre.create!(
  name: "Action RPG",
  description: "Action-oriented role-playing games"
)
```

#### 5. Game

**File:** `app/models/game.rb`  
**Migration:** `db/migrate/20251209170638_create_games.rb`

Central model representing video games.

**Attributes:**

- `title` (string, required)
- `slug` (string, unique, indexed)
- `description` (text, optional)
- `release_date` (date, optional)
- `rating_category` (enum, required) - everyone/everyone_10_plus/teen/mature/adults_only
- `metascore` (integer, 0-100, optional)
- `user_score` (decimal, 0-10, optional)
- `publisher_id` (foreign key, required)
- `developer_id` (foreign key, required)

**Associations:**

- `belongs_to :publisher`
- `belongs_to :developer`
- `has_many :game_platforms`
- `has_many :platforms, through: :game_platforms`
- `has_many :game_genres`
- `has_many :genres, through: :game_genres`
- `has_many :critic_reviews`
- `has_many :user_reviews`

**Enums:**

- `rating_category`: everyone, everyone_10_plus, teen, mature, adults_only

**Validations:**

- Title: presence
- Slug: presence, uniqueness
- Metascore: 0-100 if present
- User score: 0-10 if present

**Scopes:**

- `alphabetical` - Orders by title
- `recent` - Orders by release_date descending
- `by_metascore` - Orders by metascore descending
- `by_user_score` - Orders by user_score descending

**Example:**

```ruby
game = Game.create!(
  title: "Elden Ring",
  publisher: publisher,
  developer: developer,
  release_date: Date.new(2022, 2, 25),
  rating_category: :mature,
  metascore: 96
)
```

#### 6. GamePlatform (Join Table)

**File:** `app/models/game_platform.rb`  
**Migration:** `db/migrate/20251209170719_create_game_platforms.rb`

Links games to platforms (many-to-many).

**Attributes:**

- `game_id` (foreign key, required)
- `platform_id` (foreign key, required)

**Associations:**

- `belongs_to :game`
- `belongs_to :platform`

**Validations:**

- Uniqueness: game_id scoped to platform_id (prevents duplicates)

**Indexes:**

- Composite index on [game_id, platform_id]

#### 7. GameGenre (Join Table)

**File:** `app/models/game_genre.rb`  
**Migration:** `db/migrate/20251209170802_create_game_genres.rb`

Links games to genres (many-to-many).

**Attributes:**

- `game_id` (foreign key, required)
- `genre_id` (foreign key, required)

**Associations:**

- `belongs_to :game`
- `belongs_to :genre`

**Validations:**

- Uniqueness: game_id scoped to genre_id

**Indexes:**

- Composite index on [game_id, genre_id]

#### 8. Publication

**File:** `app/models/publication.rb`  
**Migration:** `db/migrate/20251209170833_create_publications.rb`

Represents gaming publications/outlets (IGN, GameSpot, etc.).

**Attributes:**

- `name` (string, required, unique)
- `website_url` (string, optional)
- `credibility_weight` (decimal, default: 5.0) - Used for weighted metascore calculation

**Associations:**

- `has_many :critic_reviews`

**Validations:**

- Name: presence, uniqueness
- Credibility weight: 0-10

**Scopes:**

- `by_credibility` - Orders by credibility_weight descending

**Example:**

```ruby
publication = Publication.create!(
  name: "IGN",
  website_url: "https://www.ign.com",
  credibility_weight: 8.5
)
```

#### 9. CriticReview

**File:** `app/models/critic_review.rb`  
**Migration:** `db/migrate/20251209170905_create_critic_reviews.rb`

Professional reviews from gaming publications.

**Attributes:**

- `game_id` (foreign key, required)
- `publication_id` (foreign key, required)
- `platform_id` (foreign key, optional) - Platform-specific review
- `score` (integer, 0-100, required)
- `review_url` (string, optional)
- `published_at` (datetime, optional)

**Associations:**

- `belongs_to :game`
- `belongs_to :publication`
- `belongs_to :platform, optional: true`

**Validations:**

- Score: presence, 0-100
- Uniqueness: game_id + publication_id + platform_id (one review per game/publication/platform combo)

**Example:**

```ruby
review = CriticReview.create!(
  game: game,
  publication: publication,
  platform: platform,
  score: 95,
  review_url: "https://ign.com/reviews/elden-ring"
)
```

#### 10. UserReview

**File:** `app/models/user_review.rb`  
**Migration:** `db/migrate/20251209170938_create_user_reviews.rb`

User-generated game reviews with moderation.

**Attributes:**

- `user_id` (foreign key, required)
- `game_id` (foreign key, required)
- `platform_id` (foreign key, optional)
- `title` (string, 5-100 chars, required)
- `body` (text, 50-5000 chars, required)
- `score` (decimal, 0-10, required)
- `hours_played` (integer, optional)
- `completion_status` (enum, optional) - not_completed/completed/100_percent
- `moderation_status` (enum, default: pending) - pending/approved/flagged/rejected
- `moderated_at` (datetime, optional)
- `moderated_by_id` (foreign key, optional)

**Associations:**

- `belongs_to :user`
- `belongs_to :game`
- `belongs_to :platform, optional: true`
- `belongs_to :moderated_by, class_name: "User", optional: true`

**Enums:**

- `moderation_status`: pending, approved, flagged, rejected
- `completion_status`: not_completed, completed, 100_percent

**Validations:**

- Title: presence, length 5-100
- Body: presence, length 50-5000
- Score: presence, 0-10
- Uniqueness: user_id + game_id + platform_id (one review per user/game/platform)

**Scopes:**

- `approved` - Only approved reviews
- `pending` - Pending moderation
- `recent` - Orders by created_at descending

**Example:**

```ruby
review = UserReview.create!(
  user: user,
  game: game,
  platform: platform,
  title: "Masterpiece of Game Design",
  body: "Elden Ring combines the best elements..." * 10,
  score: 9.5,
  hours_played: 120,
  completion_status: :completed
)
```

#### 11. User (Enhanced)

**File:** `app/models/user.rb`  
**Migration:** `db/migrate/20251209171043_add_role_to_users.rb`

Enhanced existing User model with role-based authorization.

**New Attributes:**

- `role` (enum, default: user) - user/moderator/admin

**New Associations:**

- `has_many :user_reviews`
- `has_many :moderated_reviews, class_name: "UserReview", foreign_key: :moderated_by_id`

**Enums:**

- `role`: user, moderator, admin

**New Methods:**

- `moderator_or_admin?` - Returns true if user is moderator or admin

### Database Constraints & Indexes

**File:** `db/migrate/20251209171316_fix_missing_constraints_and_indexes.rb`

Additional constraints and indexes added for data integrity and performance:

**Foreign Key Constraints:**

- All `belongs_to` associations have foreign key constraints with `on_delete: :cascade`

**Unique Indexes:**

- `publishers.slug`
- `developers.slug`
- `platforms.name`
- `genres.name`
- `games.slug`
- `publications.name`
- Composite: `game_platforms[game_id, platform_id]`
- Composite: `game_genres[game_id, genre_id]`
- Composite: `critic_reviews[game_id, publication_id, platform_id]`
- Composite: `user_reviews[user_id, game_id, platform_id]`

**Performance Indexes:**

- `games.publisher_id`
- `games.developer_id`
- `games.metascore`
- `games.user_score`
- `critic_reviews.game_id`
- `user_reviews.user_id`
- `user_reviews.game_id`
- `user_reviews.moderation_status`

### Seed Data

**File:** `db/seeds.rb`

Comprehensive seed data for development:

**Platforms (8):**

- PlayStation 5, Xbox Series X, Nintendo Switch, PC, PlayStation 4, Xbox One, iOS, Android

**Genres (12):**

- Action, Adventure, RPG, Strategy, Sports, Racing, Fighting, Puzzle, Simulation, Horror, Platformer, Shooter

**Publishers (8):**

- Sony Interactive Entertainment, Microsoft Game Studios, Nintendo, Electronic Arts, Activision Blizzard, Ubisoft, Take-Two Interactive, Bandai Namco

**Developers (8):**

- Naughty Dog, 343 Industries, Nintendo EPD, DICE, Infinity Ward, Ubisoft Montreal, Rockstar Games, FromSoftware

**Publications (6):**

- IGN (8.5), GameSpot (8.0), Polygon (7.5), Kotaku (7.0), PC Gamer (8.0), Eurogamer (7.5)

## Authorization (Pundit)

**Gem:** `pundit ~> 2.4`

### Application Policy

**File:** `app/policies/application_policy.rb`

Base policy with default deny-all behavior. All custom policies inherit from this.

### Game Policy

**File:** `app/policies/game_policy.rb`

Authorization rules for game CRUD operations:

- `index?` - Public access
- `show?` - Public access
- `create?` - Admin only
- `update?` - Admin only
- `destroy?` - Admin only

### User Review Policy

**File:** `app/policies/user_review_policy.rb`

Complex authorization for review moderation:

- `create?` - Authenticated users only
- `update?` - Owner only, and only if pending
- `destroy?` - Owner only, and only if pending
- `approve?` - Moderators and admins only
- `flag?` - Moderators and admins only
- `reject?` - Moderators and admins only
- `show?` - Owner can always see; others only see approved reviews

### Controller Integration

**File:** `app/controllers/application_controller.rb`

```ruby
include Pundit::Authorization

rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

private

def user_not_authorized
  flash[:alert] = "You are not authorized to perform this action."
  redirect_back(fallback_location: root_path)
end
```

## Model Testing

All models have comprehensive test coverage:

**Model Tests (11 files):**

- `test/models/publisher_test.rb` (15 tests)
- `test/models/developer_test.rb` (14 tests)
- `test/models/platform_test.rb` (17 tests)
- `test/models/genre_test.rb` (13 tests)
- `test/models/game_test.rb` (18 tests)
- `test/models/game_platform_test.rb` (6 tests)
- `test/models/game_genre_test.rb` (6 tests)
- `test/models/publication_test.rb` (14 tests)
- `test/models/critic_review_test.rb` (15 tests)
- `test/models/user_review_test.rb` (20 tests)
- `test/models/user_test.rb` (8 role tests)

**Total Model Tests:** 146 tests, 328 assertions

**Test Coverage Includes:**

- All validations (presence, uniqueness, length, numericality)
- All associations (belongs_to, has_many, through)
- Enum values and behavior
- Callbacks (slug generation)
- Scopes (alphabetical, recent, by_metascore, etc.)
- Business logic (moderator_or_admin?, etc.)

**Run model tests:**

```bash
bin/rails test test/models
```

## Background Jobs (Solid Queue)

### Queue Configuration

**Location:** `config/queue.yml`

Solid Queue is configured with multiple specialized queues:

#### Development Environment

- **default** queue: General background jobs (2 threads, 1 process)
- **mailers** queue: Email delivery jobs (2 threads, 1 process)
- **background** queue: Analytics and batch updates (1 thread, 1 process)

#### Production Environment

- **critical** queue: High-priority operations (5 threads, configurable processes)
- **default** queue: General background jobs (3 threads, configurable processes)
- **mailers** queue: Email delivery (5 threads, configurable processes)
- **background** queue: Analytics and updates (2 threads, configurable processes)
- **low_priority** queue: Cleanup and maintenance (1 thread, 1 process)

Environment variables for production scaling:

- `CRITICAL_JOB_CONCURRENCY` (default: 2)
- `DEFAULT_JOB_CONCURRENCY` (default: 3)
- `MAILER_JOB_CONCURRENCY` (default: 2)
- `BACKGROUND_JOB_CONCURRENCY` (default: 2)

### Recurring Jobs

**Location:** `config/recurring.yml`

#### Development

- **clear_solid_queue_finished_jobs**: Runs every 6 hours

#### Production

- **clear_solid_queue_finished_jobs**: Runs every hour at minute 12
- **update_game_metascores**: Runs daily at 3am (recalculates weighted metascores)
- **auto_approve_reviews**: Runs weekly on Sunday at 2am (auto-approves pending reviews older than 7 days)

### Implemented Jobs

#### GameMetascoreUpdateJob

**Queue:** `background`

Updates game metascores based on critic reviews using weighted averages by publication credibility.

```ruby
# Update specific game
GameMetascoreUpdateJob.perform_later(game_id)

# Update all games
GameMetascoreUpdateJob.perform_later
```

**Features:**

- Weighted calculation using publication credibility (0-10)
- Handles missing reviews gracefully
- Logs all metascore updates

#### ReviewAutoApprovalJob

**Queue:** `background`

Automatically approves user reviews that have been pending for 7+ days without flags.

```ruby
ReviewAutoApprovalJob.perform_later
```

**Features:**

- Only affects pending reviews
- 7-day threshold configurable via `PENDING_THRESHOLD_DAYS`
- Skips flagged/rejected reviews
- Can trigger notification emails (commented out by default)

#### ReviewNotificationJob

**Queue:** `mailers`

Sends email notifications for review status changes.

```ruby
ReviewNotificationJob.perform_later(review_id, 'approved')
ReviewNotificationJob.perform_later(review_id, 'rejected')
ReviewNotificationJob.perform_later(review_id, 'flagged')
```

**Events:**

- `approved`: Review approved and published
- `rejected`: Review rejected for guideline violations
- `flagged`: Review flagged for moderation

## Email Service

### Development Configuration

**Delivery Method:** `letter_opener`

Emails are previewed in the browser instead of being sent. When an email is triggered:

1. Email HTML/text is generated
2. Browser window opens with email preview
3. No actual email is sent

**Default URL Host:** `localhost:3000`

### Production Configuration

**Delivery Method:** SMTP (SendGrid)

**Environment Variables Required:**

- `APP_HOST`: Your domain (default: "gamesreview.com")
- `SMTP_ADDRESS`: SMTP server (default: "smtp.sendgrid.net")
- `SMTP_PORT`: SMTP port (default: 587)
- `SMTP_DOMAIN`: Your domain (default: "gamesreview.com")
- `SMTP_USERNAME`: SMTP username (default: "apikey")
- `SMTP_PASSWORD`: SMTP password (falls back to Rails credentials)

**Alternative SMTP Providers:**

- **Postmark:** Set `SMTP_ADDRESS=smtp.postmarkapp.com`, `SMTP_USERNAME=<your-token>`
- **Mailgun:** Set `SMTP_ADDRESS=smtp.mailgun.org`, `SMTP_USERNAME=<your-username>`
- **Amazon SES:** Set `SMTP_ADDRESS=email-smtp.us-east-1.amazonaws.com`

### Implemented Mailers

#### UserMailer

**Methods:**

- `welcome_email(user)`: Sent when user first registers via OAuth
- `email_verified(user)`: Sent when email verification completes

**Templates:** HTML and plain text versions in `app/views/user_mailer/`

#### ReviewNotificationMailer

**Methods:**

- `review_approved(review)`: Sent when review is approved
- `review_rejected(review)`: Sent when review is rejected
- `review_flagged(review)`: Sent when review is flagged

**Templates:** HTML and plain text versions in `app/views/review_notification_mailer/`

**Features:**

- Professional HTML emails with responsive design
- Plain text fallback for all emails
- Includes review details (title, score, excerpt)
- User-friendly explanations for each status
- Links to guidelines and relevant pages (placeholders until Phase 2 routes exist)

## Testing

All jobs and mailers have comprehensive test coverage:

**Job Tests:**

- `test/jobs/game_metascore_update_job_test.rb` (20 tests)
- `test/jobs/review_auto_approval_job_test.rb` (26 tests)
- `test/jobs/review_notification_job_test.rb` (21 tests)

**Mailer Tests:**

- `test/mailers/user_mailer_test.rb` (19 tests)
- `test/mailers/review_notification_mailer_test.rb` (32 tests)

**Run tests:**

```bash
bin/rails test test/jobs
bin/rails test test/mailers
```

## Usage Examples

### Triggering a background job in console

```ruby
# Update metascores for all games
GameMetascoreUpdateJob.perform_later

# Update specific game
game = Game.find_by(title: "The Legend of Zelda")
GameMetascoreUpdateJob.perform_later(game.id)

# Auto-approve old reviews
ReviewAutoApprovalJob.perform_later
```

### Sending emails

```ruby
# Send welcome email
user = User.last
UserMailer.welcome_email(user).deliver_later

# Send review notification
review = UserReview.last
ReviewNotificationJob.perform_later(review.id, 'approved')
```

### Monitoring jobs (Rails console)

```ruby
# View all jobs
SolidQueue::Job.all

# View failed jobs
SolidQueue::FailedExecution.all

# View scheduled jobs
SolidQueue::ScheduledExecution.all

# Clear finished jobs manually
SolidQueue::Job.clear_finished_in_batches
```

## Production Setup Checklist

- [ ] Set environment variables for SMTP credentials
- [ ] Configure `APP_HOST` environment variable
- [ ] Set job concurrency environment variables based on server capacity
- [ ] Verify SendGrid/SMTP account is active and API key is valid
- [ ] Test email delivery in staging environment
- [ ] Monitor job queue performance and adjust worker threads if needed
- [ ] Set up monitoring/alerts for failed jobs
- [ ] Configure log rotation for job logs

## Dependencies

**Gems:**

- `solid_queue`: Background job processing (Rails 8 default)
- `letter_opener`: Email preview in development

**Database:**

- Solid Queue uses PostgreSQL tables (migrations in `db/queue_schema.rb`)

## Notes

- URL helpers in mailers currently use `root_url` as placeholders. These will be updated in Phase 2 when proper routes are implemented.
- Review notification emails can be integrated into the review moderation workflow in Phase 2.
- Production SMTP credentials should be stored in Rails encrypted credentials, not plain environment variables.
