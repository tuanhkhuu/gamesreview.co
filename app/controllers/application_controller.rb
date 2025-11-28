class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_request_details
  before_action :authenticate

  private
    def authenticate
      if session_record = find_session_from_cookie
        if session_valid?(session_record)
          Current.session = session_record
        else
          expire_session(session_record)
          redirect_to sign_in_path
        end
      else
        redirect_to sign_in_path
      end
    end

    def find_session_from_cookie
      Session.find_by_id(cookies.signed[:session_token])
    end

    def session_valid?(session_record)
      session_record.created_at > 2.weeks.ago
    end

    def expire_session(session_record)
      session_record.destroy
      cookies.delete(:session_token)
    end

    def set_current_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
    end
end
