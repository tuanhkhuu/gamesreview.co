require "test_helper"

class GenreTest < ActiveSupport::TestCase
  def setup
    Genre.delete_all
  end

  test "should be valid with valid attributes" do
    genre = Genre.new(
      name: "Test Genre",
      slug: "test-genre",
      description: "A test genre description"
    )
    assert genre.valid?
  end

  test "should require name" do
    genre = Genre.new(slug: "test")
    assert_not genre.valid?
    assert_includes genre.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    Genre.create!(name: "Action", slug: "action")
    duplicate = Genre.new(name: "Action", slug: "action-2")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should require slug" do
    genre = Genre.create(name: "Test")
    assert genre.persisted?
    genre.name = nil # Prevent callback from running
    genre.slug = nil
    assert_not genre.valid?
    assert_includes genre.errors[:slug], "can't be blank"
  end

  test "should require unique slug" do
    Genre.create!(name: "Genre One", slug: "test-slug")
    duplicate = Genre.new(name: "Genre Two", slug: "test-slug")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "should validate slug format" do
    genre = Genre.new(name: "Test", slug: "Invalid Slug!")
    assert_not genre.valid?
    assert_includes genre.errors[:slug], "is invalid"
  end

  test "should auto-generate slug from name" do
    genre = Genre.new(name: "Auto Slug Genre")
    genre.valid?
    assert_equal "auto-slug-genre", genre.slug
  end

  test "should have many games through game_genres" do
    assert_respond_to Genre.new, :games
    assert_respond_to Genre.new, :game_genres
  end

  test "alphabetical scope should order by name" do
    Genre.create!(name: "Strategy", slug: "strategy")
    Genre.create!(name: "Action", slug: "action")
    Genre.create!(name: "RPG", slug: "rpg")

    genres = Genre.alphabetical
    assert_equal "Action", genres.first.name
    assert_equal "Strategy", genres.last.name
  end
end
