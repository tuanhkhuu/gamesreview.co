require "test_helper"

class CriticReviewTest < ActiveSupport::TestCase
  def setup
    # Clean all tables
    CriticReview.delete_all
    Game.delete_all
    Publication.delete_all
    Platform.delete_all
    Publisher.delete_all
    Developer.delete_all

    @publisher = Publisher.create!(name: "Test Publisher", slug: "test-publisher")
    @developer = Developer.create!(name: "Test Developer", slug: "test-developer")
    @game = Game.create!(title: "Test Game", slug: "test-game", publisher: @publisher, developer: @developer)
    @publication = Publication.create!(name: "Test Publication", slug: "test-pub")
    @platform = Platform.create!(name: "PS5", slug: "ps5", platform_type: :console)
  end

  test "should be valid with valid attributes" do
    review = CriticReview.new(
      game: @game,
      publication: @publication,
      platform: @platform,
      score: 85,
      excerpt: "A great game!",
      review_url: "https://example.com/review",
      author_name: "John Doe"
    )
    assert review.valid?
  end

  test "should require score" do
    review = CriticReview.new(game: @game, publication: @publication)
    assert_not review.valid?
    assert_includes review.errors[:score], "can't be blank"
  end

  test "should validate score range" do
    review = CriticReview.new(game: @game, publication: @publication)

    review.score = -1
    assert_not review.valid?

    review.score = 101
    assert_not review.valid?

    review.score = 85
    assert review.valid?
  end

  test "should validate score is integer" do
    review = CriticReview.new(game: @game, publication: @publication, score: 85.5)
    assert_not review.valid?
    assert_includes review.errors[:score], "must be an integer"
  end

  test "should require game" do
    review = CriticReview.new(publication: @publication, score: 85)
    assert_not review.valid?
    assert_includes review.errors[:game], "must exist"
  end

  test "should require publication" do
    review = CriticReview.new(game: @game, score: 85)
    assert_not review.valid?
    assert_includes review.errors[:publication], "must exist"
  end

  test "platform should be optional" do
    review = CriticReview.new(game: @game, publication: @publication, score: 85)
    assert review.valid?
  end

  test "should validate excerpt length" do
    review = CriticReview.new(
      game: @game,
      publication: @publication,
      score: 85,
      excerpt: "a" * 501
    )
    assert_not review.valid?
    assert_includes review.errors[:excerpt], "is too long (maximum is 500 characters)"
  end

  test "should validate review_url format when present" do
    review = CriticReview.new(game: @game, publication: @publication, score: 85, review_url: "not-a-url")
    assert_not review.valid?
    assert_includes review.errors[:review_url], "is invalid"
  end

  test "should enforce uniqueness of game, publication, and platform combination" do
    CriticReview.create!(game: @game, publication: @publication, platform: @platform, score: 85)
    duplicate = CriticReview.new(game: @game, publication: @publication, platform: @platform, score: 90)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:game_id], "already has a review from this publication for this platform"
  end

  test "should allow multiple reviews from same publication for different platforms" do
    platform2 = Platform.create!(name: "Xbox", slug: "xbox", platform_type: :console)

    CriticReview.create!(game: @game, publication: @publication, platform: @platform, score: 85)
    review2 = CriticReview.new(game: @game, publication: @publication, platform: platform2, score: 90)

    assert review2.valid?
  end

  test "recent scope should order by published_at descending" do
    old = CriticReview.create!(game: @game, publication: @publication, score: 85, published_at: 1.week.ago)
    new = CriticReview.create!(game: @game, publication: @publication, platform: @platform, score: 90, published_at: Time.current)

    reviews = CriticReview.recent
    assert_equal new.id, reviews.first.id
    assert_equal old.id, reviews.last.id
  end

  test "by_score scope should order by score descending" do
    low = CriticReview.create!(game: @game, publication: @publication, score: 50)
    high = CriticReview.create!(game: @game, publication: @publication, platform: @platform, score: 95)

    reviews = CriticReview.by_score
    assert_equal high.id, reviews.first.id
    assert_equal low.id, reviews.last.id
  end

  test "for_game scope should filter by game_id" do
    game2 = Game.create!(title: "Another Game", slug: "another", publisher: @publisher, developer: @developer)

    review1 = CriticReview.create!(game: @game, publication: @publication, score: 85)
    review2 = CriticReview.create!(game: game2, publication: @publication, score: 90)

    reviews = CriticReview.for_game(@game.id)
    assert_includes reviews, review1
    assert_not_includes reviews, review2
  end
end
