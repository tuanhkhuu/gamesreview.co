require "test_helper"

class GameGenreTest < ActiveSupport::TestCase
  def setup
    GameGenre.delete_all
    Game.delete_all
    Genre.delete_all
    Publisher.delete_all
    Developer.delete_all

    @publisher = Publisher.create!(name: "Test Publisher", slug: "test-publisher")
    @developer = Developer.create!(name: "Test Developer", slug: "test-developer")
    @game = Game.create!(title: "Test Game", slug: "test-game", publisher: @publisher, developer: @developer)
    @genre = Genre.create!(name: "Action", slug: "action")
  end

  test "should be valid with valid attributes" do
    game_genre = GameGenre.new(game: @game, genre: @genre)
    assert game_genre.valid?
  end

  test "should require game" do
    game_genre = GameGenre.new(genre: @genre)
    assert_not game_genre.valid?
    assert_includes game_genre.errors[:game], "must exist"
  end

  test "should require genre" do
    game_genre = GameGenre.new(game: @game)
    assert_not game_genre.valid?
    assert_includes game_genre.errors[:genre], "must exist"
  end

  test "should enforce uniqueness of game and genre combination" do
    GameGenre.create!(game: @game, genre: @genre)
    duplicate = GameGenre.new(game: @game, genre: @genre)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:game_id], "has already been taken"
  end

  test "should allow same game with different genres" do
    genre2 = Genre.create!(name: "RPG", slug: "rpg")

    GameGenre.create!(game: @game, genre: @genre)
    game_genre2 = GameGenre.new(game: @game, genre: genre2)

    assert game_genre2.valid?
  end

  test "should allow same genre for different games" do
    game2 = Game.create!(title: "Another Game", slug: "another", publisher: @publisher, developer: @developer)

    GameGenre.create!(game: @game, genre: @genre)
    game_genre2 = GameGenre.new(game: game2, genre: @genre)

    assert game_genre2.valid?
  end
end
