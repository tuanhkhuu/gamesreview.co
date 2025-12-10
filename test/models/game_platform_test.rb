require "test_helper"

class GamePlatformTest < ActiveSupport::TestCase
  def setup
    GamePlatform.delete_all
    Game.delete_all
    Platform.delete_all
    Publisher.delete_all
    Developer.delete_all

    @publisher = Publisher.create!(name: "Test Publisher", slug: "test-publisher")
    @developer = Developer.create!(name: "Test Developer", slug: "test-developer")
    @game = Game.create!(title: "Test Game", slug: "test-game", publisher: @publisher, developer: @developer)
    @platform = Platform.create!(name: "PS5", slug: "ps5", platform_type: :console)
  end

  test "should be valid with valid attributes" do
    game_platform = GamePlatform.new(game: @game, platform: @platform)
    assert game_platform.valid?
  end

  test "should require game" do
    game_platform = GamePlatform.new(platform: @platform)
    assert_not game_platform.valid?
    assert_includes game_platform.errors[:game], "must exist"
  end

  test "should require platform" do
    game_platform = GamePlatform.new(game: @game)
    assert_not game_platform.valid?
    assert_includes game_platform.errors[:platform], "must exist"
  end

  test "should enforce uniqueness of game and platform combination" do
    GamePlatform.create!(game: @game, platform: @platform)
    duplicate = GamePlatform.new(game: @game, platform: @platform)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:game_id], "has already been taken"
  end

  test "should allow same game on different platforms" do
    platform2 = Platform.create!(name: "Xbox", slug: "xbox", platform_type: :console)

    GamePlatform.create!(game: @game, platform: @platform)
    game_platform2 = GamePlatform.new(game: @game, platform: platform2)

    assert game_platform2.valid?
  end

  test "should allow same platform for different games" do
    game2 = Game.create!(title: "Another Game", slug: "another", publisher: @publisher, developer: @developer)

    GamePlatform.create!(game: @game, platform: @platform)
    game_platform2 = GamePlatform.new(game: game2, platform: @platform)

    assert game_platform2.valid?
  end
end
