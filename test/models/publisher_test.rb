require "test_helper"

class PublisherTest < ActiveSupport::TestCase
  def setup
    # Clean database before each test
    Publisher.delete_all
  end

  test "should be valid with valid attributes" do
    publisher = Publisher.new(
      name: "Test Publisher",
      slug: "test-publisher",
      website_url: "https://example.com",
      country: "United States"
    )
    assert publisher.valid?
  end

  test "should require name" do
    publisher = Publisher.new(slug: "test")
    assert_not publisher.valid?
    assert_includes publisher.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    Publisher.create!(name: "Unique Publisher", slug: "unique-publisher")
    duplicate = Publisher.new(name: "Unique Publisher", slug: "unique-publisher-2")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should require slug" do
    publisher = Publisher.create(name: "Test")
    assert publisher.persisted?
    publisher.name = nil # Prevent callback from running
    publisher.slug = nil
    assert_not publisher.valid?
    assert_includes publisher.errors[:slug], "can't be blank"
  end

  test "should require unique slug" do
    Publisher.create!(name: "Publisher One", slug: "test-slug")
    duplicate = Publisher.new(name: "Publisher Two", slug: "test-slug")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "should validate slug format" do
    publisher = Publisher.new(name: "Test", slug: "Invalid Slug!")
    assert_not publisher.valid?
    assert_includes publisher.errors[:slug], "is invalid"
  end

  test "should validate website_url format when present" do
    publisher = Publisher.new(name: "Test", slug: "test", website_url: "not-a-url")
    assert_not publisher.valid?
    assert_includes publisher.errors[:website_url], "is invalid"
  end

  test "should allow blank website_url" do
    publisher = Publisher.new(name: "Test", slug: "test", website_url: "")
    assert publisher.valid?
  end

  test "should auto-generate slug from name" do
    publisher = Publisher.new(name: "Auto Slug Publisher")
    publisher.valid?
    assert_equal "auto-slug-publisher", publisher.slug
  end

  test "should not overwrite manually set slug" do
    publisher = Publisher.new(name: "Test Publisher", slug: "custom-slug")
    publisher.valid?
    assert_equal "custom-slug", publisher.slug
  end

  test "should have many games" do
    assert_respond_to Publisher.new, :games
  end

  test "alphabetical scope should order by name" do
    Publisher.create!(name: "Zebra Publisher", slug: "zebra")
    Publisher.create!(name: "Alpha Publisher", slug: "alpha")
    Publisher.create!(name: "Beta Publisher", slug: "beta")

    publishers = Publisher.alphabetical
    assert_equal "Alpha Publisher", publishers.first.name
    assert_equal "Zebra Publisher", publishers.last.name
  end
end
