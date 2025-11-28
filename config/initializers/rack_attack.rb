# frozen_string_literal: true

# Skip Rack::Attack in test environment to avoid interfering with tests
return if Rails.env.test?

class Rack::Attack
  # Rate limiting configuration for GamesReview.com
  # Protects against brute force attacks and OAuth abuse

  ### Configure Cache ###
  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blocklisting and
  # safelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Configuration ###

  # Throttle all OAuth authentication attempts by IP address
  # Limit: 10 requests per 60 seconds per IP
  throttle("oauth/ip", limit: 10, period: 60.seconds) do |req|
    if req.path.start_with?("/auth/")
      req.ip
    end
  end

  # Throttle sign-in page requests by IP address
  # Limit: 5 requests per 20 seconds per IP
  throttle("sign_in/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/sign_in" && req.get?
      req.ip
    end
  end

  # Throttle OAuth callback endpoints more strictly
  # Limit: 5 requests per 30 seconds per IP
  throttle("oauth_callback/ip", limit: 5, period: 30.seconds) do |req|
    if req.path.match?(/\/auth\/\w+\/callback/)
      req.ip
    end
  end

  # Throttle account deletion attempts
  # Limit: 2 requests per hour per IP
  throttle("account_deletion/ip", limit: 2, period: 1.hour) do |req|
    if req.path == "/account" && req.delete?
      req.ip
    end
  end

  ### Custom Throttle Response ###
  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is perfect for our use case.

  # Optional: Customize throttle response
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => (now + (match_data[:period] - now % match_data[:period])).to_s,
      "Content-Type" => "text/html"
    }

    html_body = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Rate Limit Exceeded</title>
        <style>
          body { font-family: system-ui, sans-serif; max-width: 600px; margin: 100px auto; padding: 20px; text-align: center; }
          h1 { color: #dc2626; }
          p { color: #6b7280; line-height: 1.6; }
        </style>
      </head>
      <body>
        <h1>⏱️ Rate Limit Exceeded</h1>
        <p>Too many requests. Please wait a moment before trying again.</p>
        <p>You can retry after <strong>#{match_data[:period]}</strong> seconds.</p>
        <p><a href="/">Return to Home</a></p>
      </body>
      </html>
    HTML

    [ 429, headers, [ html_body ] ]
  end

  ### Logging ###
  # Log blocked requests in production
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled #{req.env["rack.attack.match_type"]} " \
                      "#{req.ip} #{req.request_method} #{req.fullpath}"
  end
end
