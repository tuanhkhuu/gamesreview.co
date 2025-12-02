require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  setup do
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.clear
  end

  test "signing in with Google for the first time" do
    setup_omniauth_for_google

    visit sign_in_path

    assert_text "Welcome to Games Review"
    assert_button "Continue with Google"

    click_button "Continue with Google"

    assert_text "Successfully signed in with Google"
    assert_current_path root_path

    # Verify user was created
    user = User.find_by(email: "google@example.com")
    assert user
    assert_equal "Google User", user.name
    assert user.email_verified
    assert_equal 1, user.oauth_identities.count
  end

  test "signing in with Twitter" do
    setup_omniauth_for_twitter

    visit sign_in_path
    click_button "Continue with Twitter"

    assert_text "Successfully signed in with Twitter"

    user = User.find_by(email: "twitter@example.com")
    assert user
    assert_equal "twitter2", user.oauth_identities.first.provider
  end

  test "signing in with Facebook" do
    setup_omniauth_for_facebook

    visit sign_in_path
    click_button "Continue with Facebook"

    assert_text "Successfully signed in with Facebook"

    user = User.find_by(email: "facebook@example.com")
    assert user
    assert_equal "facebook", user.oauth_identities.first.provider
  end

  test "linking multiple OAuth providers to same account" do
    # First sign in with Google
    setup_omniauth_for_google
    visit sign_in_path
    click_button "Continue with Google"

    assert_text "Successfully signed in with Google"

    # Visit connected accounts page
    visit oauth_identities_path

    assert_text "Connected Accounts"
    assert_text "Google"
    assert_text "Connect More Accounts"
    assert_button "Connect Facebook"

    # Connect Facebook account
    setup_omniauth_for_facebook(email: "google@example.com") # Same email
    click_button "Connect Facebook"

    assert_text "Successfully connected Facebook"

    # Verify both identities are linked to same user
    user = User.find_by(email: "google@example.com")
    assert_equal 2, user.oauth_identities.count
    assert_equal [ "facebook", "google_oauth2" ], user.oauth_identities.pluck(:provider).sort
  end

  test "disconnecting an OAuth provider" do
    # Create user with two identities
    user = User.create!(
      email: "test@example.com",
      name: "Test User",
      email_verified: true
    )

    user.oauth_identities.create!(
      provider: "google_oauth2",
      uid: "google_123",
      access_token: "google_token"
    )

    user.oauth_identities.create!(
      provider: "facebook",
      uid: "fb_123",
      access_token: "fb_token"
    )

    # Sign in
    sign_in_system_user(user)

    visit oauth_identities_path

    assert_text "Google"
    assert_text "Facebook"

    # Should have disconnect buttons
    assert_button "Disconnect", count: 2

    # Disconnect Google
    within(:xpath, "//div[contains(., 'Google')]") do
      click_button "Disconnect"
    end

    # Confirm the disconnect
    page.driver.browser.switch_to.alert.accept if page.driver.respond_to?(:browser)

    assert_text "Successfully disconnected"
    assert_no_text "Google"
    assert_text "Facebook"
  end

  test "cannot disconnect last OAuth provider" do
    user = User.create!(
      email: "test@example.com",
      name: "Test User",
      email_verified: true
    )

    user.oauth_identities.create!(
      provider: "google_oauth2",
      uid: "google_123",
      access_token: "google_token"
    )

    sign_in_system_user(user)
    visit oauth_identities_path

    assert_text "Last connection"
    assert_no_button "Disconnect"
  end

  test "handling OAuth authentication failure" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    visit sign_in_path
    click_button "Continue with Google"

    assert_text "Authentication failed"
    assert_current_path sign_in_path
  end

  test "sign out functionality" do
    setup_omniauth_for_google
    visit sign_in_path
    click_button "Continue with Google"

    assert_text "Successfully signed in"

    # Find and click sign out (you'll need to add this to your layout)
    # This is a placeholder - adjust based on your actual UI
    # click_button "Sign Out"

    # assert_text "Signed out successfully"
    # assert_current_path sign_in_path
  end

  private

  def setup_omniauth_for_google(email: "google@example.com", name: "Google User")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "google_uid_123",
      info: {
        email: email,
        name: name,
        image: "https://example.com/google.jpg",
        email_verified: true
      },
      credentials: {
        token: "google_access_token",
        refresh_token: "google_refresh_token",
        expires_at: 1.hour.from_now.to_i
      }
    })
  end

  def setup_omniauth_for_twitter(email: "twitter@example.com", name: "Twitter User")
    OmniAuth.config.mock_auth[:twitter2] = OmniAuth::AuthHash.new({
      provider: "twitter2",
      uid: "twitter_uid_123",
      info: {
        email: email,
        name: name,
        image: "https://example.com/twitter.jpg",
        email_verified: true
      },
      credentials: {
        token: "twitter_access_token",
        refresh_token: "twitter_refresh_token",
        expires_at: 1.hour.from_now.to_i
      }
    })
  end

  def setup_omniauth_for_facebook(email: "facebook@example.com", name: "Facebook User")
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
      provider: "facebook",
      uid: "facebook_uid_123",
      info: {
        email: email,
        name: name,
        image: "https://example.com/facebook.jpg",
        email_verified: true
      },
      credentials: {
        token: "facebook_access_token",
        expires_at: 1.hour.from_now.to_i
      }
    })
  end

  def sign_in_system_user(user)
    session = user.sessions.create!

    # Set the session cookie
    # This is a simplified version - you may need to adjust based on your session handling
    visit root_path
    page.driver.browser.manage.add_cookie(
      name: "session_token",
      value: session.id,
      path: "/"
    )
    visit root_path
  end
end
