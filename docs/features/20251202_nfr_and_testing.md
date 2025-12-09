# Non-Functional Requirements & Testing Strategy

**Phase:** 6-7 (Weeks 17-20)  
**Dependencies:** All previous phases  
**Status:** Ready for Implementation

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
- **NFR-9:** Background jobs shall process asynchronously (Solid Queue)

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

## Performance Optimization

### Database Indexes

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_performance_indexes.rb
class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Games
    add_index :games, :slug, unique: true
    add_index :games, :release_date
    add_index :games, :metascore
    add_index :games, :user_score
    add_index :games, [:metascore, :release_date]

    # User Reviews
    add_index :user_reviews, [:game_id, :status]
    add_index :user_reviews, [:user_id, :game_id, :platform_id], unique: true
    add_index :user_reviews, [:game_id, :status, :helpful_votes_count]
    add_index :user_reviews, :created_at

    # Critic Reviews
    add_index :critic_reviews, [:game_id, :publication_id]

    # Votes
    add_index :review_helpfulness_votes, [:user_id, :user_review_id], unique: true
    add_index :review_helpfulness_votes, [:user_review_id, :helpful]

    # GamePlatform
    add_index :game_platforms, [:game_id, :platform_id], unique: true

    # GameGenre
    add_index :game_genres, [:game_id, :genre_id], unique: true

    # Full-text search
    execute <<-SQL
      CREATE INDEX games_title_search_idx ON games USING gin(to_tsvector('english', title));
      CREATE INDEX games_description_search_idx ON games USING gin(to_tsvector('english', description));
    SQL
  end
end
```

### Caching Strategy

**Redis Cache Keys:**

```ruby
# Game detail page
cache_key = "game_#{game.id}_detail_#{game.updated_at.to_i}"
Rails.cache.fetch(cache_key, expires_in: 1.hour) do
  # Render game detail page
end

# User reviews for game
cache_key = "game_#{game.id}_reviews_#{params[:sort]}_#{params[:filter]}"
Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
  # Fetch and render reviews
end

# Metascore
cache_key = "game_#{game.id}_metascore"
Rails.cache.fetch(cache_key, expires_in: 1.day) do
  game.metascore
end

# User reputation
cache_key = "user_#{user.id}_reputation"
Rails.cache.fetch(cache_key, expires_in: 1.hour) do
  user.reputation_score
end
```

**Cache Invalidation:**

```ruby
# After review approved
class UserReview < ApplicationRecord
  after_save :invalidate_caches, if: -> { saved_change_to_status? && approved? }

  private

  def invalidate_caches
    Rails.cache.delete("game_#{game_id}_detail")
    Rails.cache.delete_matched("game_#{game_id}_reviews_*")
    Rails.cache.delete("user_#{user_id}_reputation")
  end
end
```

### N+1 Query Prevention

```ruby
# Use includes/eager loading
@games = Game.includes(:platforms, :genres, :publisher, :developer)
              .page(params[:page])

@reviews = UserReview.includes(:user, :platform, :game)
                     .approved
                     .by_helpfulness
                     .page(params[:page])

# Use counter caches
class Game < ApplicationRecord
  has_many :user_reviews, counter_cache: :user_reviews_count
  has_many :critic_reviews, counter_cache: :critic_reviews_count
end
```

---

## Testing Strategy

### Unit Tests

**Models:**

- Validations (presence, uniqueness, format, length)
- Associations (belongs_to, has_many)
- Scopes (approved, recent, by_helpfulness)
- Instance methods (calculate_metascore, rating_category)
- Callbacks (after_save, before_validation)

**Example:**

```ruby
# spec/models/user_review_spec.rb
RSpec.describe UserReview, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:body) }
    it { should validate_length_of(:body).is_at_least(75) }
    it { should validate_uniqueness_of(:user_id).scoped_to([:game_id, :platform_id]) }
  end

  describe '#sentiment' do
    it 'returns positive for scores >= 7' do
      review = build(:user_review, score: 8)
      expect(review.sentiment).to eq('positive')
    end

    it 'returns negative for scores < 4' do
      review = build(:user_review, score: 3)
      expect(review.sentiment).to eq('negative')
    end
  end
end
```

### Integration Tests

**User Flows:**

- Review submission flow
- Review moderation workflow
- Search and filtering
- Authentication and authorization

**Example:**

```ruby
# spec/requests/user_reviews_spec.rb
RSpec.describe 'User Reviews', type: :request do
  let(:user) { create(:user, email_verified: true) }
  let(:game) { create(:game) }
  let(:platform) { create(:platform) }

  before { sign_in user }

  describe 'POST /games/:game_id/reviews' do
    it 'creates a new review' do
      expect {
        post game_reviews_path(game), params: {
          user_review: {
            platform_id: platform.id,
            score: 8.5,
            body: 'Great game! ' * 10,
            completion_status: 'completed'
          }
        }
      }.to change(UserReview, :count).by(1)

      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to eq('Review submitted for moderation')
    end

    it 'rejects review below minimum length' do
      post game_reviews_path(game), params: {
        user_review: {
          platform_id: platform.id,
          score: 8,
          body: 'Too short'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

### System Tests (E2E)

**Full User Journeys:**

- Game discovery journey
- Review submission and display
- User profile management
- Admin game management

**Example:**

```ruby
# spec/system/game_discovery_spec.rb
RSpec.describe 'Game Discovery', type: :system do
  it 'allows users to browse and filter games' do
    # Setup
    action_games = create_list(:game, 5, genre: 'Action')
    rpg_games = create_list(:game, 3, genre: 'RPG')

    # Visit browse page
    visit games_path

    # Should see all games
    expect(page).to have_css('.game-card', count: 8)

    # Filter by genre
    select 'Action', from: 'Genre'
    click_button 'Apply Filters'

    # Should see only action games
    expect(page).to have_css('.game-card', count: 5)

    # Click on a game
    first('.game-card').click

    # Should be on game detail page
    expect(page).to have_current_path(game_path(action_games.first))
    expect(page).to have_css('h1', text: action_games.first.title)
  end
end
```

### Performance Tests

**Load Testing with Apache JMeter or Gatling:**

**Target Metrics:**

- Concurrent users: 1,000
- Response time p50: < 500ms
- Response time p95: < 2 seconds
- Response time p99: < 5 seconds
- Error rate: < 0.1%
- Throughput: > 100 requests/second

**Test Scenarios:**

- 70% browsing games (GET /games, /games/:slug)
- 20% viewing game details (GET /games/:slug)
- 10% submitting reviews (POST /games/:slug/reviews)

**Example JMeter Test Plan:**

```xml
<TestPlan>
  <ThreadGroup name="Game Browsing" numThreads="700">
    <HTTPSampler path="/games" method="GET"/>
    <ConstantTimer delay="1000"/>
  </ThreadGroup>

  <ThreadGroup name="Game Details" numThreads="200">
    <HTTPSampler path="/games/${game_slug}" method="GET"/>
    <ConstantTimer delay="2000"/>
  </ThreadGroup>

  <ThreadGroup name="Review Submission" numThreads="100">
    <HTTPSampler path="/games/${game_slug}/reviews" method="POST"/>
    <ConstantTimer delay="5000"/>
  </ThreadGroup>
</TestPlan>
```

### Security Tests

**Automated Security Testing:**

```ruby
# spec/security/xss_spec.rb
RSpec.describe 'XSS Prevention', type: :request do
  it 'sanitizes user input in reviews' do
    user = create(:user)
    game = create(:game)

    post game_reviews_path(game), params: {
      user_review: {
        body: '<script>alert("XSS")</script>' + 'Safe content ' * 20,
        score: 8
      }
    }, headers: { 'Authorization': "Bearer #{user.token}" }

    review = UserReview.last
    expect(review.body).not_to include('<script>')
  end
end

# spec/security/csrf_spec.rb
RSpec.describe 'CSRF Protection', type: :request do
  it 'rejects requests without CSRF token' do
    user = create(:user)
    game = create(:game)

    post game_reviews_path(game), params: {
      user_review: { body: 'Test', score: 8 }
    }, headers: { 'Authorization': "Bearer #{user.token}" }

    expect(response).to have_http_status(:forbidden)
  end
end
```

### Accessibility Tests

**WCAG 2.1 Level AA Compliance:**

```ruby
# spec/system/accessibility_spec.rb
RSpec.describe 'Accessibility', type: :system, js: true do
  it 'has no accessibility violations on game page' do
    game = create(:game)
    visit game_path(game)

    expect(page).to be_axe_clean.according_to(:wcag21aa)
  end

  it 'supports keyboard navigation' do
    visit games_path

    # Tab through game cards
    page.driver.browser.action.send_keys(:tab).perform

    # Enter key should navigate to game
    page.driver.browser.action.send_keys(:enter).perform

    expect(page).to have_current_path(/\/games\//)
  end
end
```

---

## Monitoring & Alerting

### Error Monitoring (Sentry)

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Sample rate for performance monitoring
  config.traces_sample_rate = 0.1

  # Filter sensitive data
  config.excluded_exceptions += ['ActionController::RoutingError']
  config.before_send = lambda do |event, hint|
    # Don't send user emails
    event.user.delete(:email) if event.user
    event
  end
end
```

### Performance Monitoring (New Relic/Scout APM)

**Key Metrics to Track:**

- Apdex score (> 0.95)
- Average response time (< 500ms)
- Throughput (requests/min)
- Error rate (< 0.1%)
- Database query time
- External API call time
- Background job performance

### Application Monitoring

```ruby
# config/initializers/scout_apm.rb
ScoutApm::Config.new do |config|
  config.name = ENV['SCOUT_NAME']
  config.key = ENV['SCOUT_KEY']
  config.monitor = true

  # Custom instrumentation
  config.ignore = ['/health', '/metrics']
end
```

---

## Load Testing Results Template

**Document load testing results:**

```markdown
## Load Test Results - [Date]

### Test Configuration

- Duration: 10 minutes
- Concurrent Users: 1,000
- Ramp-up Time: 2 minutes
- Test Scenarios: Browse (70%), Details (20%), Submit (10%)

### Results

| Metric              | Target      | Actual    | Status  |
| ------------------- | ----------- | --------- | ------- |
| Response Time (p50) | < 500ms     | 342ms     | ✅ PASS |
| Response Time (p95) | < 2s        | 1.8s      | ✅ PASS |
| Response Time (p99) | < 5s        | 3.2s      | ✅ PASS |
| Error Rate          | < 0.1%      | 0.05%     | ✅ PASS |
| Throughput          | > 100 req/s | 165 req/s | ✅ PASS |

### Bottlenecks Identified

1. Metascore calculation taking 200ms (add caching)
2. Review helpfulness query N+1 (add counter cache)

### Recommendations

- Implement Redis caching for metascores
- Add counter_cache for helpful_votes_count
```

---

## Testing Checklist

### Unit Tests

- [ ] All models have validation tests
- [ ] All associations tested
- [ ] All scopes tested
- [ ] All instance methods tested
- [ ] All callbacks tested
- [ ] Test coverage > 90%

### Integration Tests

- [ ] Review submission flow
- [ ] Review moderation workflow
- [ ] Search and filtering
- [ ] Authentication and authorization
- [ ] Email notifications

### System Tests

- [ ] Game discovery journey
- [ ] Review submission and display
- [ ] User profile management
- [ ] Admin game management
- [ ] Mobile responsive layouts

### Performance Tests

- [ ] Load testing with 1,000 concurrent users
- [ ] Database query performance
- [ ] Page load time benchmarks
- [ ] Caching effectiveness

### Security Tests

- [ ] SQL injection prevention
- [ ] XSS attack prevention
- [ ] CSRF token validation
- [ ] Authentication bypass attempts
- [ ] Rate limiting effectiveness

### Accessibility Tests

- [ ] WCAG 2.1 Level AA compliance
- [ ] Automated testing with axe-core-rspec
- [ ] Keyboard navigation verification
- [ ] Screen reader compatibility
- [ ] Color contrast validation

---

**Next Step:** Launch Preparation (Phase 7)
