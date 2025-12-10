require "test_helper"

class PlatformTest < ActiveSupport::TestCase
  def setup
    Platform.delete_all
  end

  test "should be valid with valid attributes" do
    platform = Platform.new(
      name: "Test Platform",
      slug: "test-platform",
      short_name: "TP",
      platform_type: :console,
      manufacturer: "Test Corp",
      active: true
    )
    assert platform.valid?
  end

  test "should require name" do
    platform = Platform.new(slug: "test", platform_type: :console)
    assert_not platform.valid?
    assert_includes platform.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    Platform.create!(name: "PlayStation 5", slug: "ps5", platform_type: :console)
    duplicate = Platform.new(name: "PlayStation 5", slug: "ps5-2", platform_type: :console)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "should require platform_type" do
    platform = Platform.new(name: "Test", slug: "test")
    platform.platform_type = nil
    assert_not platform.valid?
    assert_includes platform.errors[:platform_type], "can't be blank"
  end

  test "should validate slug format" do
    platform = Platform.new(name: "Test", slug: "Invalid Slug!", platform_type: :console)
    assert_not platform.valid?
    assert_includes platform.errors[:slug], "is invalid"
  end

  test "should auto-generate slug from name" do
    platform = Platform.new(name: "Auto Slug Platform", platform_type: :console)
    platform.valid?
    assert_equal "auto-slug-platform", platform.slug
  end

  test "should have platform_type enum" do
    platform = Platform.new(name: "Test", slug: "test")

    platform.platform_type = :console
    assert platform.console?

    platform.platform_type = :pc
    assert platform.pc?

    platform.platform_type = :mobile
    assert platform.mobile?
  end

  test "should default active to true" do
    platform = Platform.new(name: "Test", slug: "test", platform_type: :console)
    platform.save!
    assert platform.active?
  end

  test "should have many games through game_platforms" do
    assert_respond_to Platform.new, :games
    assert_respond_to Platform.new, :game_platforms
  end

  test "alphabetical scope should order by name" do
    Platform.create!(name: "Xbox", slug: "xbox", platform_type: :console)
    Platform.create!(name: "Android", slug: "android", platform_type: :mobile)
    Platform.create!(name: "PlayStation", slug: "playstation", platform_type: :console)

    platforms = Platform.alphabetical
    assert_equal "Android", platforms.first.name
    assert_equal "Xbox", platforms.last.name
  end

  test "active scope should return only active platforms" do
    Platform.create!(name: "Active Platform", slug: "active", platform_type: :console, active: true)
    Platform.create!(name: "Inactive Platform", slug: "inactive", platform_type: :console, active: false)

    active_platforms = Platform.active
    assert_equal 1, active_platforms.count
    assert_equal "Active Platform", active_platforms.first.name
  end
end
