ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Suppress OmniAuth logger during tests to keep output clean
OmniAuth.config.logger = Logger.new(nil)

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Don't use fixtures - we create data in tests
  # fixtures :all

  setup do
    # Clear all data before each test
    OauthIdentity.delete_all
    Session.delete_all
    User.delete_all
  end

  # Add more helper methods to be used by all tests here...

  # Sign in a user for integration tests
  # This uses the actual OAuth callback flow to set cookies properly
  def sign_in_as(user)
    # Ensure user has an OAuth identity
    identity = user.oauth_identities.first_or_create!(
      provider: "google_oauth2",
      uid: "test_uid_#{user.id}",
      access_token: "test_token"
    )

    # Set up OmniAuth mock for this user
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: identity.uid,
      info: {
        email: user.email,
        name: user.name,
        image: user.avatar_url,
        email_verified: user.email_verified
      },
      credentials: {
        token: identity.access_token,
        refresh_token: "test_refresh",
        expires_at: 1.hour.from_now.to_i
      }
    })

    # Trigger the OAuth callback - this will set the session cookie properly
    get "/auth/google_oauth2/callback"

    # Follow the redirect to complete the sign-in
    follow_redirect! if response.redirect?

    user
  end

  # Sign out the current user
  def sign_out
    cookies.delete(:session_token)
    Current.session = nil
  end

  # OmniAuth test helpers
  def setup_omniauth_mock(provider: "google_oauth2", uid: "123456",
                          email: "test@example.com", name: "Test User",
                          email_verified: true, picture: "https://example.com/pic.jpg")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[provider.to_sym] = OmniAuth::AuthHash.new({
      provider: provider,
      uid: uid,
      info: {
        email: email,
        name: name,
        image: picture,
        email_verified: email_verified
      },
      credentials: {
        token: "mock_access_token",
        refresh_token: "mock_refresh_token",
        expires_at: 1.hour.from_now.to_i
      },
      extra: {
        raw_info: {
          email: email,
          name: name,
          picture: picture,
          email_verified: email_verified
        }
      }
    })
  end

  def clear_omniauth_mock
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.clear
  end
end
