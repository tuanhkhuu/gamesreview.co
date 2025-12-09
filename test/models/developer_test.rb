require "test_helper"

class DeveloperTest < ActiveSupport::TestCase
  def setup
    Developer.delete_all
  end

  test "should be valid with valid attributes" do
    developer = Developer.new(
      name: "Test Developer",
      slug: "test-developer",
      website_url: "https://example.com",
      country: "Japan"
    )
    assert developer.valid?
  end

  test "should require name" do
    developer = Developer.new(slug: "test")
    assert_not developer.valid?
    assert_includes developer.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    Developer.create!(name: "Unique Developer", slug: "unique-dev")
    duplicate = Developer.new(name: "Unique Developer", slug: "unique-dev-2")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should require slug" do
    developer = Developer.create(name: "Test")
    assert developer.persisted?
    developer.name = nil # Prevent callback from running
    developer.slug = nil
    assert_not developer.valid?
    assert_includes developer.errors[:slug], "can't be blank"
  end

  test "should require unique slug" do
    Developer.create!(name: "Developer One", slug: "test-slug")
    duplicate = Developer.new(name: "Developer Two", slug: "test-slug")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "should validate slug format" do
    developer = Developer.new(name: "Test", slug: "Invalid Slug!")
    assert_not developer.valid?
    assert_includes developer.errors[:slug], "is invalid"
  end

  test "should auto-generate slug from name" do
    developer = Developer.new(name: "Auto Slug Developer")
    developer.valid?
    assert_equal "auto-slug-developer", developer.slug
  end

  test "should have many games" do
    assert_respond_to Developer.new, :games
  end

  test "alphabetical scope should order by name" do
    Developer.create!(name: "Zebra Studios", slug: "zebra")
    Developer.create!(name: "Alpha Games", slug: "alpha")
    Developer.create!(name: "Beta Interactive", slug: "beta")

    developers = Developer.alphabetical
    assert_equal "Alpha Games", developers.first.name
    assert_equal "Zebra Studios", developers.last.name
  end
end
