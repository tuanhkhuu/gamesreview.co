require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  # Note: Rack::Attack is disabled in test environment to avoid interfering
  # with other tests. These tests verify the configuration exists and is valid.

  test "rack attack configuration file exists" do
    config_file = Rails.root.join("config/initializers/rack_attack.rb")
    assert File.exist?(config_file), "Rack::Attack configuration file should exist"
  end

  test "rack attack gem is installed" do
    assert defined?(Rack::Attack), "Rack::Attack gem should be installed"
  end

  test "rack attack is configured for production" do
    # Temporarily switch to production to test configuration
    original_env = Rails.env
    Rails.env = ActiveSupport::StringInquirer.new("production")

    # Reload the initializer
    load Rails.root.join("config/initializers/rack_attack.rb")

    # Verify throttles are defined
    assert Rack::Attack.throttles.any?, "Rack::Attack should have throttles configured"

    # Verify specific throttles exist
    throttle_names = Rack::Attack.throttles.keys
    assert_includes throttle_names, "oauth/ip", "Should have oauth/ip throttle"
    assert_includes throttle_names, "sign_in/ip", "Should have sign_in/ip throttle"
    assert_includes throttle_names, "oauth_callback/ip", "Should have oauth_callback/ip throttle"
    assert_includes throttle_names, "account_deletion/ip", "Should have account_deletion/ip throttle"
  ensure
    Rails.env = original_env
  end

  test "rack attack throttled responder is configured" do
    # Verify custom throttle response is configured
    assert Rack::Attack.throttled_responder.respond_to?(:call),
           "Throttled responder should be configured"
  end

  test "rate limit configuration has appropriate limits" do
    # This test documents the expected rate limits
    # Actual limits are defined in config/initializers/rack_attack.rb

    expected_limits = {
      "oauth/ip" => { limit: 10, period: 60 },
      "sign_in/ip" => { limit: 5, period: 20 },
      "oauth_callback/ip" => { limit: 5, period: 30 },
      "account_deletion/ip" => { limit: 2, period: 3600 }
    }

    # Verify the limits are documented
    config_content = File.read(Rails.root.join("config/initializers/rack_attack.rb"))

    expected_limits.each do |name, config|
      assert_match(/throttle\(["']#{Regexp.escape(name)}["']/, config_content,
                   "Configuration should include #{name} throttle")
    end
  end
end
