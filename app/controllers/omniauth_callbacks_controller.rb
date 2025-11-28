# Handles OAuth provider callbacks
class OmniauthCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create, :failure ]
  skip_before_action :authenticate

  # Handles all OAuth provider callbacks
  # GET /auth/:provider/callback
  def create
    # Validate provider is supported
    unless OauthIdentity::SUPPORTED_PROVIDERS.include?(auth_hash.provider)
      redirect_to sign_in_path, alert: "Unsupported OAuth provider"
      return
    end

    result = OauthAuthenticationService.new(auth_hash).call

    if result.success
      start_new_session_for(result.user)

      if result.new_user
        redirect_to root_path, notice: "Welcome! Your account has been created."
      else
        redirect_to root_path, notice: "Signed in successfully."
      end
    else
      handle_authentication_error(result)
    end
  end

  # Handles OAuth failures
  # GET /auth/failure
  def failure
    error_type = params[:error_reason] || params[:message] || "unknown_error"
    provider = params[:strategy]

    Rails.logger.warn "[OAuth] Authentication failed: #{error_type} for provider: #{provider}"

    redirect_to sign_in_path, alert: oauth_error_message(error_type)
  end

  private

  def auth_hash
    request.env["omniauth.auth"]
  end

  def start_new_session_for(user)
    reset_session  # Prevent session fixation attacks

    session = user.sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )

    Current.session = session
    cookies.signed.permanent[:session_token] = {
      value: session.id,
      httponly: true,
      secure: Rails.env.production?,  # HTTPS only in production
      same_site: :lax  # CSRF protection
    }
  end

  def handle_authentication_error(result)
    case result.error_type
    when :email_conflict
      redirect_to sign_in_path, alert: result.error
    when :validation_error
      redirect_to sign_in_path, alert: "Unable to create account. Please try again."
    else
      redirect_to sign_in_path, alert: "Authentication failed. Please try again."
    end
  end

  def oauth_error_message(error_type)
    case error_type.to_sym
    when :access_denied, :user_denied
      "You cancelled the sign in process."
    when :invalid_credentials
      "Invalid OAuth credentials. Please contact support."
    when :redirect_uri_mismatch
      "OAuth configuration error. Please contact support."
    else
      "Authentication failed. Please try again."
    end
  end

  def authenticate
    # Override to skip authentication for this controller
  end
end
