class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_request_details
  before_action :authenticate

  private
    def authenticate
      # Test environment bypass: allow setting user directly via header
      if Rails.env.test? && request.headers["X-Test-User-Id"].present?
        user = User.find_by(id: request.headers["X-Test-User-Id"])
        if user
          # Find or create a test session with a unique identifier
          session_record = user.sessions.find_or_create_by!(
            user_agent: "Test Authentication",
            ip_address: "0.0.0.0"
          )
          Current.session = session_record
          return
        end
      end

      if session_record = Session.find_by_id(cookies.signed[:session_token])
        # Check if session has expired (2 weeks, matching cookie expiration)
        if session_record.created_at > 2.weeks.ago
          Current.session = session_record
        else
          # Clean up expired session
          session_record.destroy
          cookies.delete(:session_token)
          redirect_to sign_in_path
        end
      else
        redirect_to sign_in_path
      end
    end
    def set_current_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
    end
end
