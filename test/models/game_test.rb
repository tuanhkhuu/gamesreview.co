require "test_helper"

class GameTest < ActiveSupport::TestCase
  def setup
    # Clean all related tables
    Game.delete_all
    Publisher.delete_all
    Developer.delete_all
    Platform.delete_all
    Genre.delete_all

    @publisher = Publisher.create!(name: "Test Publisher", slug: "test-publisher")
    @developer = Developer.create!(name: "Test Developer", slug: "test-developer")
  end

  test "should be valid with valid attributes" do
    game = Game.new(
      title: "Test Game",
      slug: "test-game",
      publisher: @publisher,
      developer: @developer
    )
    assert game.valid?
  end

  test "should require title" do
    game = Game.new(slug: "test", publisher: @publisher, developer: @developer)
    assert_not game.valid?
    assert_includes game.errors[:title], "can't be blank"
  end

  test "should require slug" do
    game = Game.create(title: "Test", publisher: @publisher, developer: @developer)
    assert game.persisted?
    game.title = nil # Prevent callback from running
    game.slug = nil
    assert_not game.valid?
    assert_includes game.errors[:slug], "can't be blank"
  end

  test "should require unique slug" do
    Game.create!(title: "Game One", slug: "test-slug", publisher: @publisher, developer: @developer)
    duplicate = Game.new(title: "Game Two", slug: "test-slug", publisher: @publisher, developer: @developer)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "should validate slug format" do
    game = Game.new(title: "Test", slug: "Invalid Slug!", publisher: @publisher, developer: @developer)
    assert_not game.valid?
    assert_includes game.errors[:slug], "is invalid"
  end

  test "should require publisher" do
    game = Game.new(title: "Test", slug: "test", developer: @developer)
    assert_not game.valid?
    assert_includes game.errors[:publisher], "must exist"
  end

  test "should require developer" do
    game = Game.new(title: "Test", slug: "test", publisher: @publisher)
    assert_not game.valid?
    assert_includes game.errors[:developer], "must exist"
  end

  test "should validate metascore range" do
    game = Game.new(title: "Test", slug: "test", publisher: @publisher, developer: @developer)

    game.metascore = -1
    assert_not game.valid?

    game.metascore = 101
    assert_not game.valid?

    game.metascore = 50
    assert game.valid?
  end

  test "should validate user_score range" do
    game = Game.new(title: "Test", slug: "test", publisher: @publisher, developer: @developer)

    game.user_score = -1
    assert_not game.valid?

    game.user_score = 11
    assert_not game.valid?

    game.user_score = 8.5
    assert game.valid?
  end

  test "should auto-generate slug from title" do
    game = Game.new(title: "Auto Slug Game", publisher: @publisher, developer: @developer)
    game.valid?
    assert_equal "auto-slug-game", game.slug
  end

  test "should have rating_category enum" do
    game = Game.new(title: "Test", slug: "test", publisher: @publisher, developer: @developer)

    game.rating_category = :everyone
    assert game.everyone?

    game.rating_category = :mature
    assert game.mature?
  end

  test "should have many platforms through game_platforms" do
    game = Game.create!(title: "Test", slug: "test", publisher: @publisher, developer: @developer)
    platform = Platform.create!(name: "PS5", slug: "ps5", platform_type: :console)

    game.platforms << platform
    assert_includes game.platforms, platform
  end

  test "should have many genres through game_genres" do
    game = Game.create!(title: "Test", slug: "test", publisher: @publisher, developer: @developer)
    genre = Genre.create!(name: "Action", slug: "action")

    game.genres << genre
    assert_includes game.genres, genre
  end

  test "alphabetical scope should order by title" do
    Game.create!(title: "Zelda", slug: "zelda", publisher: @publisher, developer: @developer)
    Game.create!(title: "Mario", slug: "mario", publisher: @publisher, developer: @developer)

    games = Game.alphabetical
    assert_equal "Mario", games.first.title
    assert_equal "Zelda", games.last.title
  end

  test "recent scope should order by release_date descending" do
    old_game = Game.create!(title: "Old Game", slug: "old", publisher: @publisher, developer: @developer, release_date: 1.year.ago)
    new_game = Game.create!(title: "New Game", slug: "new", publisher: @publisher, developer: @developer, release_date: Date.today)

    games = Game.recent
    assert_equal new_game.id, games.first.id
    assert_equal old_game.id, games.last.id
  end

  test "by_metascore scope should order by metascore descending" do
    low_score = Game.create!(title: "Low Score", slug: "low", publisher: @publisher, developer: @developer, metascore: 50)
    high_score = Game.create!(title: "High Score", slug: "high", publisher: @publisher, developer: @developer, metascore: 95)

    games = Game.by_metascore
    assert_equal high_score.id, games.first.id
    assert_equal low_score.id, games.last.id
  end
end
