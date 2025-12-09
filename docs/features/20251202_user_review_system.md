# Feature: User Review System

**Phase:** 4 (Weeks 11-14)  
**Dependencies:** Phase 1 (UserReview model, authorization) + Phase 2 (Game pages) + Phase 3 (Review display patterns)  
**Status:** Ready for Implementation

---

## User Stories

- **US-4:** I want to filter reviews by completion status so I see reviews from players who finished the game
- **US-7:** I want to write reviews for games I've played so I can share my experience
- **US-8:** I want to rate difficulty and playtime so others know what to expect
- **US-9:** I want to specify which platform I played on so my review is accurate
- **US-10:** I want to edit my reviews after submission so I can update my thoughts
- **US-11:** I want to track my review history so I can see all my submitted reviews
- **US-12:** I want to review flagged content so I can maintain community standards (moderator)
- **US-13:** I want to approve/reject pending reviews so I can prevent spam (moderator)

---

## Functional Requirements

### FR-3: User Review System

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

---

## Database Schema

### UserReview Model

```ruby
class UserReview < ApplicationRecord
  belongs_to :user
  belongs_to :game
  belongs_to :platform
  has_many :review_helpfulness_votes, dependent: :destroy
  has_paper_trail # Track edit history

  enum status: {
    pending: 'pending',
    approved: 'approved',
    rejected: 'rejected',
    flagged: 'flagged'
  }

  enum completion_status: {
    playing: 'playing',
    completed: 'completed',
    dropped: 'dropped'
  }

  validates :body, presence: true, length: { minimum: 75, maximum: 5000 }
  validates :title, length: { maximum: 100 }, allow_blank: true
  validates :score, presence: true, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 10
  }
  validates :playtime_hours, numericality: {
    greater_than_or_equal_to: 0,
    allow_nil: true
  }
  validates :difficulty_rating, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 5,
    allow_nil: true
  }
  validates :user_id, uniqueness: {
    scope: [:game_id, :platform_id],
    message: "can only submit one review per game per platform"
  }

  validate :user_account_requirements
  validate :edit_window

  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_helpfulness, -> {
    left_joins(:review_helpfulness_votes)
      .group(:id)
      .order('COUNT(review_helpfulness_votes.id) DESC, user_reviews.created_at DESC')
  }
  scope :positive, -> { where('score >= ?', 7) }
  scope :mixed, -> { where('score >= ? AND score < ?', 4, 7) }
  scope :negative, -> { where('score < ?', 4) }

  after_save :update_game_user_score, if: :approved?
  after_save :auto_approve_trusted_user
  after_destroy :update_game_user_score

  def helpful_votes_count
    review_helpfulness_votes.where(helpful: true).count
  end

  def sentiment
    return 'positive' if score >= 7
    return 'mixed' if score >= 4
    'negative'
  end

  private

  def user_account_requirements
    return unless user

    if user.created_at > 24.hours.ago
      errors.add(:user, 'account must be at least 24 hours old')
    end

    unless user.email_verified?
      errors.add(:user, 'must have verified email address')
    end
  end

  def edit_window
    return if new_record?
    return if !body_changed? && !score_changed?

    if created_at < 30.days.ago
      errors.add(:base, 'reviews can only be edited within 30 days of submission')
    end
  end

  def auto_approve_trusted_user
    return unless pending?
    return unless user.trusted_reviewer?

    update_column(:status, 'approved')
  end

  def update_game_user_score
    UpdateUserScoreJob.perform_later(game.id)
  end
end
```

### User Model Extensions

```ruby
class User < ApplicationRecord
  has_many :user_reviews
  has_many :review_helpfulness_votes

  def trusted_reviewer?
    # Auto-approve if user has:
    # - 10+ approved reviews
    # - 80% approval rate
    # - No flagged reviews in last 30 days
    approved_count = user_reviews.approved.count
    total_count = user_reviews.count
    recent_flagged = user_reviews.flagged.where('created_at > ?', 30.days.ago).any?

    approved_count >= 10 &&
      (approved_count.to_f / total_count >= 0.8) &&
      !recent_flagged
  end

  def reviews_this_day
    user_reviews.where('created_at > ?', 24.hours.ago).count
  end
end
```

---

## User Score Calculation

### Algorithm

```ruby
class Game < ApplicationRecord
  def calculate_user_score
    reviews = user_reviews.approved
    return nil if reviews.empty?

    total_score = reviews.sum(:score)
    (total_score.to_f / reviews.count).round(1)
  end

  def user_score_distribution
    reviews = user_reviews.approved
    return { positive: 0, mixed: 0, negative: 0 } if reviews.empty?

    total = reviews.count
    {
      positive: ((reviews.positive.count.to_f / total) * 100).round,
      mixed: ((reviews.mixed.count.to_f / total) * 100).round,
      negative: ((reviews.negative.count.to_f / total) * 100).round
    }
  end
end
```

### Background Job

```ruby
class UpdateUserScoreJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = Game.find(game_id)
    new_user_score = game.calculate_user_score
    distribution = game.user_score_distribution

    game.update_columns(
      user_score: new_user_score,
      user_score_updated_at: Time.current,
      positive_review_percentage: distribution[:positive],
      mixed_review_percentage: distribution[:mixed],
      negative_review_percentage: distribution[:negative]
    )

    Rails.cache.delete("game_#{game.id}_detail")
  end
end
```

---

## UI Specifications

### Review Submission Form

**Page:** `/games/:game_slug/reviews/new`

**Form Fields:**

1. **Game** (read-only display, pre-selected)
2. **Platform** (required, dropdown)
   - Options: All platforms for this game
3. **Rating** (required)
   - Visual slider or star selector
   - Display: 0-10 scale with 0.5 increments
4. **Review Title** (optional)
   - Text input, max 100 chars
   - Placeholder: "Sum up your review in one sentence"
5. **Review Body** (required)
   - Rich text editor (ActionText)
   - Min 75 chars, max 5000 chars
   - Character counter
6. **Completion Status** (required, radio buttons)
   - ○ Playing
   - ○ Completed
   - ○ Dropped
7. **Hours Played** (optional)
   - Number input, 0-9999
8. **Difficulty Rating** (optional)
   - 1-5 star selector
   - Labels: Very Easy, Easy, Medium, Hard, Very Hard
9. **Contains Spoilers** (optional, checkbox)
   - ☐ This review contains spoilers

**Buttons:**

- "Save Draft" (left)
- "Preview" (middle)
- "Submit Review" (right, primary)

**Validations (Real-time):**

- Body length indicator (green when >= 75 chars)
- Platform required
- Score required
- Duplicate review check (user + game + platform)
- Rate limit check (5 reviews per 24 hours)

### Review Display (Game Detail Page)

**Section Header:**

- "User Reviews" title
- User score badge (large, color-coded)
- Score distribution bar chart
- "Write a Review" button (authenticated users)

**Filters & Sort:**

- **Sort dropdown:** Most Helpful (default), Most Recent, Highest Score, Lowest Score
- **Filter buttons:** All, Positive, Mixed, Negative
- **Platform filter:** Dropdown if game has multiple platforms
- **Completion filter:** All, Completed Only, Playing, Dropped

**Review Card:**

```
┌─────────────────────────────────────────────┐
│ [Avatar] Username              [8.5/10] 🟢 │
│          Played on PS5                      │
│          Completed • 45 hours • ★★★★☆       │
│                                             │
│ Review Title (if provided)                  │
│                                             │
│ Review body text goes here... Lorem ipsum   │
│ dolor sit amet, consectetur adipiscing...   │
│                                             │
│ 👍 523 found this helpful  [Helpful?] [No]  │
│ Posted 3 days ago                           │
│                                             │
│ [⚠️ Report] (if not own review)            │
│ [✏️ Edit] [🗑️ Delete] (if own review)      │
└─────────────────────────────────────────────┘
```

**Spoiler Handling:**

- Reviews marked as spoilers show:
  - "This review contains spoilers"
  - Blurred text
  - "Show Spoilers" button to reveal

---

## Moderation Interface

**Page:** `/moderator/reviews`

**List View:**

- Tabs: Pending, Flagged, All
- Table columns: User, Game, Score, Status, Submitted, Actions
- Sort by: Date, Score, Reports
- Filter by: Status, Score range, Platform

**Review Card (Moderator View):**

- Same as public view plus:
  - Report count and reasons
  - User history: Review count, approval rate
  - Moderation notes (internal)
  - Action buttons: Approve, Reject, Flag, Delete

**Moderation Actions:**

1. **Approve**

   - Changes status to 'approved'
   - Review becomes visible
   - Updates game user score
   - Email notification to user (optional)

2. **Reject**

   - Changes status to 'rejected'
   - Review hidden from public
   - Email notification to user with reason
   - Does not count toward user score

3. **Flag**

   - Changes status to 'flagged'
   - Requires further review
   - User notified
   - Visible only to moderators

4. **Delete**
   - Soft delete (keep in database)
   - Permanently hidden
   - Email notification to user

**Moderation Notes:**

- Internal text field
- Visible only to moderators
- Track reason for rejection/flagging

---

## Edit History (GDPR Compliance)

### Implementation (using PaperTrail gem)

```ruby
# Gemfile
gem 'paper_trail'

# Migration
create_table :versions do |t|
  t.string   :item_type, null: false
  t.integer  :item_id,   null: false
  t.string   :event,     null: false
  t.string   :whodunnit
  t.text     :object
  t.text     :object_changes
  t.datetime :created_at
end

# Model
class UserReview < ApplicationRecord
  has_paper_trail on: [:update],
                  only: [:body, :title, :score]
end
```

**View Edit History:**

- Moderator can view edit history
- Shows: Original version, edited version, diff
- Timestamp and editor

---

## Draft Auto-Save

### Implementation

```javascript
// Stimulus controller: review_form_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];
  static values = { autosaveUrl: String };

  connect() {
    this.autosaveInterval = setInterval(() => {
      this.saveDraft();
    }, 30000); // Every 30 seconds
  }

  disconnect() {
    clearInterval(this.autosaveInterval);
  }

  saveDraft() {
    const formData = new FormData(this.formTarget);
    formData.append("draft", "true");

    fetch(this.autosaveUrlValue, {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.success) {
          this.showSaveIndicator();
        }
      });
  }

  showSaveIndicator() {
    // Show "Draft saved" message for 2 seconds
  }
}
```

---

## Spam & Abuse Prevention

### FR-9: Spam & Abuse Prevention

**FR-9.1: Rate Limiting**

```ruby
# In controller
class UserReviewsController < ApplicationController
  before_action :check_rate_limit, only: [:create]

  def check_rate_limit
    if current_user.reviews_this_day >= 5
      flash[:error] = "You can only submit 5 reviews per day"
      redirect_to game_path(@game) and return
    end
  end
end
```

**FR-9.2: Content Filtering**

```ruby
# Profanity filter
gem 'obscenity'

class UserReview < ApplicationRecord
  validate :check_profanity

  private

  def check_profanity
    if Obscenity.profane?(body)
      errors.add(:body, 'contains inappropriate language')
    end
  end
end
```

**FR-9.3: Reporting System**

```ruby
class ReviewReport < ApplicationRecord
  belongs_to :user_review
  belongs_to :reporter, class_name: 'User'

  enum reason: {
    spam: 'spam',
    offensive: 'offensive',
    spoilers: 'spoilers',
    off_topic: 'off_topic',
    other: 'other'
  }

  validates :reason, presence: true
  validates :user_review_id, uniqueness: {
    scope: :reporter_id,
    message: "already reported by you"
  }

  after_create :auto_flag_if_threshold

  private

  def auto_flag_if_threshold
    if user_review.review_reports.count >= 5
      user_review.update(status: 'flagged')
      NotifyModeratorsJob.perform_later(user_review.id)
    end
  end
end
```

---

## GDPR Compliance

### Data Export

```ruby
class User < ApplicationRecord
  def export_data
    {
      profile: {
        email: email,
        username: username,
        created_at: created_at
      },
      reviews: user_reviews.map do |review|
        {
          game: review.game.title,
          score: review.score,
          body: review.body,
          created_at: review.created_at
        }
      end,
      votes: review_helpfulness_votes.map do |vote|
        {
          review_id: vote.user_review_id,
          helpful: vote.helpful,
          created_at: vote.created_at
        }
      end
    }.to_json
  end
end
```

### Account Deletion (Anonymization)

```ruby
class User < ApplicationRecord
  def anonymize_and_delete
    # Keep reviews but anonymize
    user_reviews.update_all(
      user_id: User.find_by(username: '[deleted]').id
    )

    # Delete votes
    review_helpfulness_votes.destroy_all

    # Anonymize user data
    update(
      email: "deleted_#{id}@deleted.com",
      username: "[deleted_user_#{id}]",
      deleted_at: Time.current
    )
  end
end
```

---

## Testing Checklist

- [ ] Submit review (all fields)
- [ ] Submit review (required fields only)
- [ ] Validate min body length (75 chars)
- [ ] Validate max body length (5000 chars)
- [ ] Validate duplicate review (same user + game + platform)
- [ ] Validate rate limit (5 reviews per 24 hours)
- [ ] Validate account age (> 24 hours)
- [ ] Validate email verified
- [ ] Edit review within 30 days
- [ ] Reject edit after 30 days
- [ ] Auto-approve trusted reviewer
- [ ] Moderator approve review
- [ ] Moderator reject review
- [ ] Moderator flag review
- [ ] Report review (5+ reports auto-flag)
- [ ] View edit history (moderator)
- [ ] Draft auto-save (every 30s)
- [ ] Filter reviews (positive/mixed/negative)
- [ ] Sort reviews (helpful, recent, score)
- [ ] User score calculation correct
- [ ] Score distribution display
- [ ] Export user data (GDPR)
- [ ] Anonymize deleted accounts

---

**Next Phase:** Phase 5 - Community Features (Gamification)
