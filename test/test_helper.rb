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

  # Clean database between tests
  parallelize_setup do |worker|
    ActiveRecord::Base.connection.execute("TRUNCATE users, oauth_identities, sessions RESTART IDENTITY CASCADE")
  end

  setup do
    # Clear all data before each test
    OauthIdentity.delete_all
    Session.delete_all
    User.delete_all
  end

  # Add more helper methods to be used by all tests here...
  def sign_in_as(user)
    session_record = user.sessions.create!(
      user_agent: "Test Browser",
      ip_address: "127.0.0.1"
    )
    # For controller/integration tests, set Current.session directly
    # This bypasses the cookie authentication
    Current.session = session_record
    user
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
