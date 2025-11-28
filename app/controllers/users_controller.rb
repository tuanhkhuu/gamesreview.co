class UsersController < ApplicationController
  before_action :authenticate

  def destroy
    # GDPR-compliant account deletion
    # Destroys all user data including OAuth identities and sessions
    user = Current.user

    # Log the deletion for audit purposes
    Rails.logger.info "Account deletion requested by user #{user.id} (#{user.email})"

    # Delete all associated OAuth identities
    user.oauth_identities.destroy_all

    # Delete all sessions
    user.sessions.destroy_all

    # Delete the user account
    user.destroy

    # Clear session and cookies
    reset_session
    cookies.delete(:session_token)

    # Redirect to home page with confirmation
    redirect_to root_path, notice: "Your account has been permanently deleted. We're sorry to see you go!"
  end
end
