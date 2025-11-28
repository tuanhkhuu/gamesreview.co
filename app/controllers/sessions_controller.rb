class SessionsController < ApplicationController
  skip_before_action :authenticate, only: %i[ new ]

  before_action :set_session, only: :destroy

  def index
    @sessions = Current.user.sessions.order(created_at: :desc)
  end

  def new
    # OAuth-only authentication - show provider buttons
  end

  # Removed password-based create action - OAuth only
  # Authentication is handled by OmniauthCallbacksController

  def destroy
    @session.destroy
    cookies.delete(:session_token)  # Clear the cookie
    reset_session  # Clear Rails session
    redirect_to sign_in_path, notice: "Signed out successfully"
  end

  private
    def set_session
      @session = Current.user.sessions.find(params[:id])
    end
end
