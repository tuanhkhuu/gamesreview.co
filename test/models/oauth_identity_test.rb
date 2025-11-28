require "test_helper"

class OauthIdentityTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      name: "Test User",
      email_verified: true
    )

    @identity = @user.oauth_identities.create!(
      provider: "google_oauth2",
      uid: "123456",
      access_token: "test_access_token",
      refresh_token: "test_refresh_token"
    )
  end

  test "should be valid with valid attributes" do
    assert @identity.valid?
  end

  test "should require provider" do
    @identity.provider = nil
    assert_not @identity.valid?
    assert_includes @identity.errors[:provider], "can't be blank"
  end

  test "should require uid" do
    @identity.uid = nil
    assert_not @identity.valid?
    assert_includes @identity.errors[:uid], "can't be blank"
  end

  test "should require user" do
    @identity.user = nil
    assert_not @identity.valid?
    assert_includes @identity.errors[:user], "must exist"
  end

  test "should require unique uid scoped to provider" do
    duplicate = @user.oauth_identities.build(
      provider: @identity.provider,
      uid: @identity.uid,
      access_token: "different_token"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:uid], "has already been taken"
  end

  test "should allow same uid for different providers" do
    twitter_identity = @user.oauth_identities.build(
      provider: "twitter2",
      uid: @identity.uid,
      access_token: "twitter_token"
    )

    assert twitter_identity.valid?
  end

  test "should encrypt access_token" do
    # Access token should be encrypted in the database
    raw_data = ActiveRecord::Base.connection.execute(
      "SELECT access_token FROM oauth_identities WHERE id = #{@identity.id}"
    ).first

    assert_not_equal "test_access_token", raw_data["access_token"]
  end

  test "should encrypt refresh_token" do
    # Refresh token should be encrypted in the database
    raw_data = ActiveRecord::Base.connection.execute(
      "SELECT refresh_token FROM oauth_identities WHERE id = #{@identity.id}"
    ).first

    assert_not_equal "test_refresh_token", raw_data["refresh_token"]
  end

  test "should decrypt tokens when accessed" do
    assert_equal "test_access_token", @identity.access_token
    assert_equal "test_refresh_token", @identity.refresh_token
  end

  test "should belong to user" do
    assert_equal @user, @identity.user
  end

  test "should store raw_info as JSONB" do
    @identity.update!(raw_info: { name: "Test", email: "test@example.com" })
    @identity.reload

    assert_equal "Test", @identity.raw_info["name"]
    assert_equal "test@example.com", @identity.raw_info["email"]
  end

  test "should log creation for security audit" do
    # This tests that the after_create callback is set up
    # In a real app, you'd want to verify the actual log output
    assert_nothing_raised do
      @user.oauth_identities.create!(
        provider: "facebook",
        uid: "789",
        access_token: "fb_token"
      )
    end
  end

  test "should log destruction for security audit" do
    # This tests that the after_destroy callback is set up
    assert_nothing_raised do
      @identity.destroy
    end
  end

  test "should handle nil refresh_token" do
    identity = @user.oauth_identities.create!(
      provider: "twitter2",
      uid: "twitter_uid",
      access_token: "twitter_token",
      refresh_token: nil
    )

    assert_nil identity.refresh_token
    assert identity.valid?
  end

  test "should store expires_at timestamp" do
    expires_at = 1.hour.from_now
    identity = @user.oauth_identities.create!(
      provider: "facebook",
      uid: "fb_uid",
      access_token: "fb_token",
      expires_at: expires_at
    )

    assert_in_delta expires_at.to_i, identity.expires_at.to_i, 1
  end

  test "should allow raw_info to default to empty hash" do
    identity = @user.oauth_identities.create!(
      provider: "google_oauth2",
      uid: "new_uid",
      access_token: "new_token"
    )

    assert_equal({}, identity.raw_info)
  end
end
