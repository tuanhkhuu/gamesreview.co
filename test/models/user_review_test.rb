require "test_helper"

class UserReviewTest < ActiveSupport::TestCase
  def setup
    # Clean all tables
    UserReview.delete_all
    User.delete_all
    Game.delete_all
    Platform.delete_all
    Publisher.delete_all
    Developer.delete_all

    @user = User.create!(email: "test@example.com", email_verified: true)
    @publisher = Publisher.create!(name: "Test Publisher", slug: "test-publisher")
    @developer = Developer.create!(name: "Test Developer", slug: "test-developer")
    @game = Game.create!(title: "Test Game", slug: "test-game", publisher: @publisher, developer: @developer)
    @platform = Platform.create!(name: "PS5", slug: "ps5", platform_type: :console)
  end

  test "should be valid with valid attributes" do
    review = UserReview.new(
      user: @user,
      game: @game,
      platform: @platform,
      title: "Great game!",
      body: "This is a detailed review of the game. It has more than 50 characters which is required.",
      score: 8.5,
      completion_status: :completed,
      hours_played: 20
    )
    assert review.valid?
  end

  test "should require title" do
    review = UserReview.new(
      user: @user,
      game: @game,
      body: "a" * 50,
      score: 8.0
    )
    assert_not review.valid?
    assert_includes review.errors[:title], "can't be blank"
  end

  test "should validate title minimum length" do
    review = UserReview.new(
      user: @user,
      game: @game,
      title: "abc",
      body: "a" * 50,
      score: 8.0
    )
    assert_not review.valid?
    assert_includes review.errors[:title], "is too short (minimum is 5 characters)"
  end

  test "should validate title maximum length" do
    review = UserReview.new(
      user: @user,
      game: @game,
      title: "a" * 101,
      body: "a" * 50,
      score: 8.0
    )
    assert_not review.valid?
    assert_includes review.errors[:title], "is too long (maximum is 100 characters)"
  end

  test "should require body" do
    review = UserReview.new(user: @user, game: @game, title: "Great game", score: 8.0)
    assert_not review.valid?
    assert_includes review.errors[:body], "can't be blank"
  end

  test "should validate body minimum length" do
    review = UserReview.new(
      user: @user,
      game: @game,
      title: "Great game",
      body: "Too short",
      score: 8.0
    )
    assert_not review.valid?
    assert_includes review.errors[:body], "is too short (minimum is 50 characters)"
  end

  test "should validate body maximum length" do
    review = UserReview.new(
      user: @user,
      game: @game,
      title: "Great game",
      body: "a" * 5001,
      score: 8.0
    )
    assert_not review.valid?
    assert_includes review.errors[:body], "is too long (maximum is 5000 characters)"
  end

  test "should require score" do
    review = UserReview.new(
      user: @user,
      game: @game,
      title: "Great game",
      body: "a" * 50
    )
    assert_not review.valid?
    assert_includes review.errors[:score], "can't be blank"
  end

  test "should validate score range" do
    review = UserReview.new(
      user: @user,
      game: @game,
      title: "Great game",
      body: "a" * 50
    )

    review.score = -1
    assert_not review.valid?

    review.score = 11
    assert_not review.valid?

    review.score = 8.5
    assert review.valid?
  end

  test "should validate hours_played is non-negative" do
    review = UserReview.new(
      user: @user,
      game: @game,
      title: "Great game",
      body: "a" * 50,
      score: 8.0,
      hours_played: -5
    )
    assert_not review.valid?
    assert_includes review.errors[:hours_played], "must be greater than or equal to 0"
  end

  test "should default moderation_status to pending" do
    review = UserReview.new(
      user: @user,
      game: @game,
      title: "Great game",
      body: "a" * 50,
      score: 8.0
    )
    assert_equal "pending", review.moderation_status
  end

  test "should have moderation_status enum" do
    review = UserReview.create!(
      user: @user,
      game: @game,
      title: "Great game",
      body: "a" * 50,
      score: 8.0
    )

    assert review.pending?

    review.moderation_status = :approved
    assert review.approved?

    review.moderation_status = :flagged
    assert review.flagged?

    review.moderation_status = :rejected
    assert review.rejected?
  end

  test "should have completion_status enum" do
    review = UserReview.new(user: @user, game: @game, title: "Test", body: "a" * 50, score: 8.0)

    review.completion_status = :completed
    assert review.completed?

    review.completion_status = :playing
    assert review.playing?
  end

  test "should enforce uniqueness of user, game, and platform combination" do
    UserReview.create!(
      user: @user,
      game: @game,
      platform: @platform,
      title: "First review",
      body: "a" * 50,
      score: 8.0
    )

    duplicate = UserReview.new(
      user: @user,
      game: @game,
      platform: @platform,
      title: "Second review",
      body: "b" * 50,
      score: 9.0
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "can only review a game once per platform"
  end

  test "should allow user to review same game on different platforms" do
    platform2 = Platform.create!(name: "Xbox", slug: "xbox", platform_type: :console)

    UserReview.create!(
      user: @user,
      game: @game,
      platform: @platform,
      title: "PS5 review",
      body: "a" * 50,
      score: 8.0
    )

    review2 = UserReview.new(
      user: @user,
      game: @game,
      platform: platform2,
      title: "Xbox review",
      body: "b" * 50,
      score: 9.0
    )

    assert review2.valid?
  end

  test "approved scope should return only approved reviews" do
    approved = UserReview.create!(
      user: @user,
      game: @game,
      title: "Approved",
      body: "a" * 50,
      score: 8.0,
      moderation_status: :approved
    )

    pending = UserReview.create!(
      user: @user,
      game: @game,
      platform: @platform,
      title: "Pending",
      body: "b" * 50,
      score: 9.0,
      moderation_status: :pending
    )

    reviews = UserReview.approved
    assert_includes reviews, approved
    assert_not_includes reviews, pending
  end

  test "for_game scope should filter by game_id" do
    game2 = Game.create!(title: "Another Game", slug: "another", publisher: @publisher, developer: @developer)

    review1 = UserReview.create!(user: @user, game: @game, title: "Review 1", body: "a" * 50, score: 8.0)
    review2 = UserReview.create!(user: @user, game: game2, title: "Review 2", body: "b" * 50, score: 9.0)

    reviews = UserReview.for_game(@game.id)
    assert_includes reviews, review1
    assert_not_includes reviews, review2
  end
end
