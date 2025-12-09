# Feature: Gamification & Community

**Phase:** 5 (Weeks 15-16)  
**Dependencies:** Phase 4 (UserReview, user profiles)  
**Status:** Ready for Implementation

---

## User Stories

- **US-6:** I want to mark reviews as helpful so the best reviews rise to the top
- **US-11:** I want to track my review history so I can see all my submitted reviews
- **US-14:** I want to see user reputation scores so I can identify trustworthy reviewers (moderator)

---

## Functional Requirements

### FR-4: Review Helpfulness System

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

### FR-6: User Profile & Gamification

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

---

## Database Schema

### ReviewHelpfulnessVote Model

```ruby
class ReviewHelpfulnessVote < ApplicationRecord
  belongs_to :user_review
  belongs_to :user

  validates :user_id, uniqueness: {
    scope: :user_review_id,
    message: "can only vote once per review"
  }
  validates :helpful, inclusion: { in: [true, false] }

  after_create :update_review_helpfulness_cache
  after_update :update_review_helpfulness_cache
  after_destroy :update_review_helpfulness_cache

  private

  def update_review_helpfulness_cache
    UpdateReviewHelpfulnessJob.perform_later(user_review.id)
  end
end
```

### UserReview Extensions

```ruby
class UserReview < ApplicationRecord
  has_many :review_helpfulness_votes

  # Cached counts
  # helpful_votes_count :integer (cached)
  # not_helpful_votes_count :integer (cached)

  def calculate_helpful_votes
    review_helpfulness_votes.where(helpful: true).count
  end

  def calculate_not_helpful_votes
    review_helpfulness_votes.where(helpful: false).count
  end

  def helpfulness_ratio
    total = helpful_votes_count + not_helpful_votes_count
    return 0 if total.zero?

    (helpful_votes_count.to_f / total * 100).round
  end
end
```

### User Extensions (Reputation)

```ruby
class User < ApplicationRecord
  has_many :user_reviews
  has_many :review_helpfulness_votes

  # Cached stats
  # reputation_score :integer (cached)
  # total_helpful_votes :integer (cached)
  # total_reviews_count :integer (cached)

  def calculate_reputation_score
    # Reputation = (Reviews × 10) + (Helpful Votes × 2)
    reviews_score = user_reviews.approved.count * 10
    votes_score = total_helpful_votes * 2

    reviews_score + votes_score
  end

  def calculate_total_helpful_votes
    UserReview.joins(:review_helpfulness_votes)
      .where(user_id: id)
      .where(review_helpfulness_votes: { helpful: true })
      .count
  end

  def average_review_score
    reviews = user_reviews.approved
    return nil if reviews.empty?

    (reviews.average(:score) || 0).round(1)
  end

  def achievement_badges
    badges = []

    review_count = user_reviews.approved.count
    helpful_count = total_helpful_votes

    # Review milestones
    badges << { name: 'Novice Reviewer', icon: '🥉', description: '10 reviews' } if review_count >= 10
    badges << { name: 'Veteran Reviewer', icon: '🥈', description: '50 reviews' } if review_count >= 50
    badges << { name: 'Master Reviewer', icon: '🥇', description: '100 reviews' } if review_count >= 100
    badges << { name: 'Legend', icon: '👑', description: '500 reviews' } if review_count >= 500

    # Helpfulness milestones
    badges << { name: 'Helpful', icon: '👍', description: '100 helpful votes' } if helpful_count >= 100
    badges << { name: 'Very Helpful', icon: '💎', description: '500 helpful votes' } if helpful_count >= 500
    badges << { name: 'Community Hero', icon: '⭐', description: '1000 helpful votes' } if helpful_count >= 1000

    # Special badges
    badges << { name: 'Trusted Reviewer', icon: '✓', description: 'Auto-approved reviews' } if trusted_reviewer?
    badges << { name: 'Early Adopter', icon: '🌟', description: 'Joined in first month' } if created_at < Date.new(2025, 2, 1)

    badges
  end

  def most_reviewed_genres
    Genre.joins(games: :user_reviews)
      .where(user_reviews: { user_id: id, status: 'approved' })
      .group('genres.id')
      .order('COUNT(user_reviews.id) DESC')
      .limit(3)
  end

  def most_reviewed_platforms
    Platform.joins(user_reviews: :game)
      .where(user_reviews: { user_id: id, status: 'approved' })
      .group('platforms.id')
      .order('COUNT(user_reviews.id) DESC')
      .limit(3)
  end
end
```

---

## Voting UI

### Helpful Buttons (on Review Card)

**Display:**

```
👍 523 found this helpful  [👍 Helpful?] [👎 No]
```

**States:**

1. **Not voted** (default)

   - Both buttons outlined, neutral color
   - Text: "Was this review helpful?"

2. **Voted Helpful**

   - Helpful button filled, green
   - No button outlined
   - Text: "You found this helpful"
   - Click again to remove vote

3. **Voted Not Helpful**
   - No button filled, red
   - Helpful button outlined
   - Text: "You didn't find this helpful"
   - Click again to remove vote

**Stimulus Controller:**

```javascript
// helpfulness_vote_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["count", "helpfulButton", "notHelpfulButton"];
  static values = {
    reviewId: Number,
    voteUrl: String,
    currentVote: String, // "helpful", "not_helpful", or ""
  };

  voteHelpful() {
    if (this.currentVoteValue === "helpful") {
      this.removeVote();
    } else {
      this.submitVote(true);
    }
  }

  voteNotHelpful() {
    if (this.currentVoteValue === "not_helpful") {
      this.removeVote();
    } else {
      this.submitVote(false);
    }
  }

  submitVote(helpful) {
    fetch(this.voteUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
      },
      body: JSON.stringify({ helpful: helpful }),
    })
      .then((response) => response.json())
      .then((data) => {
        this.updateUI(data);
      });
  }

  removeVote() {
    fetch(this.voteUrlValue, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": this.csrfToken,
      },
    })
      .then((response) => response.json())
      .then((data) => {
        this.updateUI(data);
      });
  }

  updateUI(data) {
    this.countTarget.textContent = `${data.count} found this helpful`;
    this.currentVoteValue = data.user_vote;

    // Update button states
    if (data.user_vote === "helpful") {
      this.helpfulButtonTarget.classList.add("active");
      this.notHelpfulButtonTarget.classList.remove("active");
    } else if (data.user_vote === "not_helpful") {
      this.helpfulButtonTarget.classList.remove("active");
      this.notHelpfulButtonTarget.classList.add("active");
    } else {
      this.helpfulButtonTarget.classList.remove("active");
      this.notHelpfulButtonTarget.classList.remove("active");
    }
  }

  get csrfToken() {
    return document.querySelector('[name="csrf-token"]').content;
  }
}
```

---

## User Profile Page

**URL:** `/users/:username`

### Profile Header

```
┌─────────────────────────────────────────────────┐
│  [Avatar]  Username                             │
│            Member since: January 2025           │
│            ⭐ Reputation: 1,234                  │
│                                                 │
│  📊 Stats:                                      │
│  • 45 Reviews                                   │
│  • 523 Helpful Votes Received                   │
│  • Average Score: 7.8/10                        │
│                                                 │
│  🏆 Badges:                                     │
│  🥈 Veteran Reviewer  💎 Very Helpful           │
│  ✓ Trusted Reviewer                             │
└─────────────────────────────────────────────────┘
```

### Review History Section

**Tabs:**

- All Reviews (default)
- Positive (7-10)
- Mixed (4-6.9)
- Negative (0-3.9)

**Filter/Sort:**

- Sort: Most Recent, Most Helpful, Highest Score, Lowest Score
- Filter by Platform
- Filter by Genre

**Review List:**

- Show review cards (same as game detail page)
- Include game cover and title
- Show score, platform, helpful votes
- Link to full review on game page

### Favorite Genres/Platforms

```
Most Reviewed Genres:
🎮 Action (15 reviews)
🧩 Puzzle (12 reviews)
🏃 Platformer (8 reviews)

Most Reviewed Platforms:
🎮 PlayStation 5 (20 reviews)
💻 PC (15 reviews)
🎮 Nintendo Switch (10 reviews)
```

---

## Reputation Leaderboard

**Page:** `/leaderboard`

**Tabs:**

- Top Reviewers (by reputation score)
- Most Helpful (by helpful votes)
- Most Active (by review count)

**Table Columns:**

- Rank (#1, #2, etc.)
- User (avatar + username)
- Reviews Count
- Helpful Votes
- Reputation Score
- Badges (show top badge)

**Filter:**

- All Time (default)
- This Month
- This Year

---

## Background Jobs

### Update Review Helpfulness Cache

```ruby
class UpdateReviewHelpfulnessJob < ApplicationJob
  queue_as :default

  def perform(user_review_id)
    review = UserReview.find(user_review_id)

    helpful_count = review.calculate_helpful_votes
    not_helpful_count = review.calculate_not_helpful_votes

    review.update_columns(
      helpful_votes_count: helpful_count,
      not_helpful_votes_count: not_helpful_count
    )
  end
end
```

### Update User Reputation

```ruby
class UpdateUserReputationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    reputation_score = user.calculate_reputation_score
    total_helpful = user.calculate_total_helpful_votes
    total_reviews = user.user_reviews.approved.count

    user.update_columns(
      reputation_score: reputation_score,
      total_helpful_votes: total_helpful,
      total_reviews_count: total_reviews
    )
  end
end
```

---

## Achievement System

### Badge Definitions

```ruby
# app/models/badge.rb
class Badge
  BADGES = {
    novice_reviewer: {
      name: 'Novice Reviewer',
      icon: '🥉',
      description: 'Submitted 10 reviews',
      requirement: -> (user) { user.total_reviews_count >= 10 }
    },
    veteran_reviewer: {
      name: 'Veteran Reviewer',
      icon: '🥈',
      description: 'Submitted 50 reviews',
      requirement: -> (user) { user.total_reviews_count >= 50 }
    },
    master_reviewer: {
      name: 'Master Reviewer',
      icon: '🥇',
      description: 'Submitted 100 reviews',
      requirement: -> (user) { user.total_reviews_count >= 100 }
    },
    legend: {
      name: 'Legend',
      icon: '👑',
      description: 'Submitted 500 reviews',
      requirement: -> (user) { user.total_reviews_count >= 500 }
    },
    helpful: {
      name: 'Helpful',
      icon: '👍',
      description: 'Received 100 helpful votes',
      requirement: -> (user) { user.total_helpful_votes >= 100 }
    },
    very_helpful: {
      name: 'Very Helpful',
      icon: '💎',
      description: 'Received 500 helpful votes',
      requirement: -> (user) { user.total_helpful_votes >= 500 }
    },
    community_hero: {
      name: 'Community Hero',
      icon: '⭐',
      description: 'Received 1000 helpful votes',
      requirement: -> (user) { user.total_helpful_votes >= 1000 }
    },
    trusted_reviewer: {
      name: 'Trusted Reviewer',
      icon: '✓',
      description: 'Reviews are auto-approved',
      requirement: -> (user) { user.trusted_reviewer? }
    },
    early_adopter: {
      name: 'Early Adopter',
      icon: '🌟',
      description: 'Joined in the first month',
      requirement: -> (user) { user.created_at < Date.new(2025, 2, 1) }
    }
  }

  def self.for_user(user)
    BADGES.select { |key, badge| badge[:requirement].call(user) }
          .map { |key, badge| badge }
  end
end
```

### Badge Notifications

```ruby
# After review approved
class UserReview < ApplicationRecord
  after_save :check_new_badges, if: -> { saved_change_to_status? && approved? }

  private

  def check_new_badges
    CheckUserBadgesJob.perform_later(user.id)
  end
end

class CheckUserBadgesJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)

    # Get current badges
    current_badges = Badge.for_user(user).map { |b| b[:name] }

    # Get previously earned badges from user preferences
    previous_badges = user.earned_badges || []

    # Find new badges
    new_badges = current_badges - previous_badges

    if new_badges.any?
      # Update user's earned badges
      user.update(earned_badges: current_badges)

      # Send notification
      new_badges.each do |badge_name|
        BadgeEarnedMailer.notify(user, badge_name).deliver_later
      end
    end
  end
end
```

---

## Spam Prevention Integration

### FR-9: Spam & Abuse Prevention (Continued)

**Auto-Flag Reviews:**

- Low reputation users (< 100) with 5+ reports
- Users with 50%+ rejection rate
- Reviews with excessive negative votes

**Reputation Penalties:**

- Rejected review: -10 reputation
- Flagged review: -5 reputation
- Deleted review: -20 reputation

**Reputation Rewards:**

- Approved review: +10 reputation
- Helpful vote received: +2 reputation
- Badge earned: +50 reputation

---

## Testing Checklist

- [ ] Vote review as helpful
- [ ] Vote review as not helpful
- [ ] Change vote from helpful to not helpful
- [ ] Remove vote
- [ ] Prevent duplicate votes (same user + review)
- [ ] Update helpful count in real-time
- [ ] Sort reviews by helpfulness
- [ ] View user profile page
- [ ] Display review history on profile
- [ ] Calculate reputation score correctly
- [ ] Display achievement badges
- [ ] Award new badges automatically
- [ ] Send badge earned notification
- [ ] Most reviewed genres/platforms display
- [ ] Leaderboard displays correctly
- [ ] Filter leaderboard by timeframe
- [ ] Trusted reviewer auto-approval works
- [ ] Reputation penalties apply correctly
- [ ] Cache updates after votes

---

**Next Phase:** Phase 6 - Optimization & Polish
