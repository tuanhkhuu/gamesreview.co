require "test_helper"

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "existing@example.com",
      name: "Existing User",
      email_verified: true
    )
  end

  teardown do
    clear_omniauth_mock
  end

  test "should create new user and identity on successful Google authentication" do
    setup_omniauth_mock(
      provider: "google_oauth2",
      email: "new@example.com",
      name: "New User"
    )

    assert_difference [ "User.count", "OauthIdentity.count" ], 1 do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to root_path
    assert_equal "Welcome! Your account has been created.", flash[:notice]

    user = User.find_by(email: "new@example.com")
    assert user
    assert_equal "New User", user.name
    assert user.email_verified
    assert_equal 1, user.oauth_identities.count
  end

  test "should find existing user and create new identity when email matches" do
    setup_omniauth_mock(
      provider: "google_oauth2",
      email: @user.email,
      email_verified: true
    )

    assert_difference "OauthIdentity.count", 1 do
      assert_no_difference "User.count" do
        get "/auth/google_oauth2/callback"
      end
    end

    assert_redirected_to root_path
    @user.reload
    assert_equal 1, @user.oauth_identities.count
    assert_equal "google_oauth2", @user.oauth_identities.first.provider
  end

  test "should create session on successful authentication" do
    setup_omniauth_mock

    assert_difference "Session.count", 1 do
      get "/auth/google_oauth2/callback"
    end

    assert session[:session_id].present?
  end

  test "should handle authentication failure gracefully" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    get "/auth/google_oauth2/callback"

    assert_redirected_to sign_in_path
    assert_equal "Authentication failed. Please try again.", flash[:alert]
  end

  test "should handle missing email from provider" do
    setup_omniauth_mock(email: nil)

    get "/auth/google_oauth2/callback"

    assert_redirected_to sign_in_path
    assert flash[:alert].present?
  end

  test "should not link accounts when email is unverified" do
    setup_omniauth_mock(
      provider: "google_oauth2",
      email: @user.email,
      email_verified: false
    )

    # Should not create new user or link account
    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to sign_in_path
    assert flash[:alert].present?
  end


  test "should link identity to existing user" do
    identity = @user.oauth_identities.create!(
      provider: "google_oauth2",
      uid: "existing_uid",
      access_token: "old_token"
    )

    setup_omniauth_mock(
      provider: "google_oauth2",
      uid: "existing_uid",
      email: @user.email,
      name: "Updated Name",
      picture: "https://example.com/new.jpg"
    )

    get "/auth/google_oauth2/callback"

    @user.reload
    assert_redirected_to root_path
    assert_equal "Signed in successfully.", flash[:notice]
  end

  test "should store OAuth tokens encrypted" do
    setup_omniauth_mock

    get "/auth/google_oauth2/callback"

    identity = OauthIdentity.last

    # Tokens should be accessible
    assert_equal "mock_access_token", identity.access_token
    assert_equal "mock_refresh_token", identity.refresh_token

    # But should be encrypted in the database
    raw_data = ActiveRecord::Base.connection.execute(
      "SELECT access_token FROM oauth_identities WHERE id = #{identity.id}"
    ).first

    assert_not_equal "mock_access_token", raw_data["access_token"]
  end
end
