# Session configuration with security settings
Rails.application.config.session_store :cookie_store,
  key: "_gamesreview_session",
  expire_after: 2.weeks,  # Session timeout
  secure: Rails.env.production?,  # HTTPS only in production
  httponly: true,  # Prevent JavaScript access
  same_site: :lax  # CSRF protection
