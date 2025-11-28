# OmniAuth configuration for OAuth providers
Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth 2.0
  provider :google_oauth2,
    Rails.application.credentials.dig(:oauth, :google, :client_id) || ENV["GOOGLE_CLIENT_ID"],
    Rails.application.credentials.dig(:oauth, :google, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"],
    {
      scope: "email,profile",
      prompt: "select_account",
      image_aspect_ratio: "square",
      image_size: 200,
      name: "google_oauth2"
    }

  # Twitter OAuth 2.0
  provider :twitter2,
    Rails.application.credentials.dig(:oauth, :twitter, :client_id) || ENV["TWITTER_CLIENT_ID"],
    Rails.application.credentials.dig(:oauth, :twitter, :client_secret) || ENV["TWITTER_CLIENT_SECRET"],
    {
      scope: "tweet.read users.read offline.access",
      name: "twitter2"
    }

  # Facebook OAuth
  provider :facebook,
    Rails.application.credentials.dig(:oauth, :facebook, :app_id) || ENV["FACEBOOK_APP_ID"],
    Rails.application.credentials.dig(:oauth, :facebook, :app_secret) || ENV["FACEBOOK_APP_SECRET"],
    {
      scope: "email,public_profile",
      info_fields: "email,name,picture",
      name: "facebook"
    }
end

# Handle OmniAuth failures
OmniAuth.config.on_failure = proc { |env|
  OmniauthCallbacksController.action(:failure).call(env)
}

# Allow test mode in test environment
OmniAuth.config.test_mode = Rails.env.test?
