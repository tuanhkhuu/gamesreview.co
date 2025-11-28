require "test_helper"

class OauthIdentitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "test@example.com",
      name: "Test User",
      email_verified: true
    )

    @google_identity = @user.oauth_identities.create!(
      provider: "google_oauth2",
      uid: "google_123",
      access_token: "google_token"
    )

    @twitter_identity = @user.oauth_identities.create!(
      provider: "twitter2",
      uid: "twitter_123",
      access_token: "twitter_token"
    )

    # Create session for the user
    @session = @user.sessions.create!(
      user_agent: "Test Browser",
      ip_address: "127.0.0.1"
    )
  end

  test "should get index" do
    sign_in_as(@user)
    get oauth_identities_url

    assert_response :success
    assert_select "h1", "Connected Accounts"
  end

  test "should show all connected identities" do
    sign_in_as(@user)
    get oauth_identities_url

    assert_response :success
    # Check that both providers are shown
    assert_match /Google/, response.body
    assert_match /Twitter/, response.body
  end

  test "should show available providers" do
    # User has Google and Twitter, so Facebook should be available
    sign_in_as(@user)
    get oauth_identities_url

    assert_response :success
    assert_match /Facebook/, response.body
    assert_match /Connect/, response.body
  end

  test "should destroy identity when user has multiple" do
    sign_in_as(@user)
    assert_difference("OauthIdentity.count", -1) do
      delete oauth_identity_url(@google_identity)
    end

    assert_redirected_to oauth_identities_path
    assert flash[:notice].present?
  end

  test "should not destroy last identity" do
    # Delete one identity first
    @twitter_identity.destroy

    sign_in_as(@user)
    assert_no_difference "OauthIdentity.count" do
      delete oauth_identity_url(@google_identity)
    end

    assert_redirected_to oauth_identities_path
    assert flash[:alert].present?
  end

  test "should only allow user to delete their own identities" do
    other_user = User.create!(
      email: "other@example.com",
      name: "Other User",
      email_verified: true
    )

    other_identity = other_user.oauth_identities.create!(
      provider: "google_oauth2",
      uid: "other_123",
      access_token: "other_token"
    )

    sign_in_as(@user)
    assert_no_difference "OauthIdentity.count" do
      delete oauth_identity_url(other_identity)
    end

    assert_redirected_to oauth_identities_path
  end

  test "should require authentication to access index" do
    # Don't sign in
    get oauth_identities_url

    assert_redirected_to sign_in_path
  end

  test "should require authentication to delete identity" do
    # Don't sign in
    delete oauth_identity_url(@google_identity)

    assert_redirected_to sign_in_path
  end
end
