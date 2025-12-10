require "test_helper"

class PublicationTest < ActiveSupport::TestCase
  def setup
    Publication.delete_all
  end

  test "should be valid with valid attributes" do
    publication = Publication.new(
      name: "Test Publication",
      slug: "test-publication",
      website_url: "https://example.com",
      credibility_weight: 8.0
    )
    assert publication.valid?
  end

  test "should require name" do
    publication = Publication.new(slug: "test")
    assert_not publication.valid?
    assert_includes publication.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    Publication.create!(name: "IGN", slug: "ign")
    duplicate = Publication.new(name: "IGN", slug: "ign-2")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should require slug" do
    publication = Publication.create(name: "Test")
    assert publication.persisted?
    publication.name = nil # Prevent callback from running
    publication.slug = nil
    assert_not publication.valid?
    assert_includes publication.errors[:slug], "can't be blank"
  end

  test "should validate slug format" do
    publication = Publication.new(name: "Test", slug: "Invalid Slug!")
    assert_not publication.valid?
    assert_includes publication.errors[:slug], "is invalid"
  end

  test "should validate credibility_weight range" do
    publication = Publication.new(name: "Test", slug: "test")

    publication.credibility_weight = -1
    assert_not publication.valid?

    publication.credibility_weight = 11
    assert_not publication.valid?

    publication.credibility_weight = 8.5
    assert publication.valid?
  end

  test "should default credibility_weight to 5.0" do
    publication = Publication.create!(name: "Test", slug: "test")
    assert_equal 5.0, publication.credibility_weight
  end

  test "should auto-generate slug from name" do
    publication = Publication.new(name: "Auto Slug Publication")
    publication.valid?
    assert_equal "auto-slug-publication", publication.slug
  end

  test "should have many critic_reviews" do
    assert_respond_to Publication.new, :critic_reviews
  end

  test "alphabetical scope should order by name" do
    Publication.create!(name: "Polygon", slug: "polygon")
    Publication.create!(name: "GameSpot", slug: "gamespot")
    Publication.create!(name: "IGN", slug: "ign")

    publications = Publication.alphabetical
    assert_equal "GameSpot", publications.first.name
    assert_equal "Polygon", publications.last.name
  end

  test "by_credibility scope should order by credibility_weight descending" do
    low = Publication.create!(name: "Low Cred", slug: "low", credibility_weight: 3.0)
    high = Publication.create!(name: "High Cred", slug: "high", credibility_weight: 9.0)

    publications = Publication.by_credibility
    assert_equal high.id, publications.first.id
    assert_equal low.id, publications.last.id
  end
end
