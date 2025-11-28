# Manages user's connected OAuth accounts
class OauthIdentitiesController < ApplicationController
  before_action :set_identity, only: [ :destroy ]

  # GET /oauth_identities
  def index
    @oauth_identities = Current.user.oauth_identities.order(created_at: :desc)
    @available_providers = available_providers
  end

  # DELETE /oauth_identities/:id
  def destroy
    if Current.user.oauth_identities.count <= 1
      redirect_to oauth_identities_path,
        alert: "Cannot disconnect your last login method. Connect another provider first."
      return
    end

    @identity.destroy!
    redirect_to oauth_identities_path, notice: "#{@identity.provider.titleize} account disconnected."
  end

  private

  def set_identity
    @identity = Current.user.oauth_identities.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to oauth_identities_path, alert: "Identity not found."
  end

  def available_providers
    connected = Current.user.oauth_identities.pluck(:provider)
    all_providers = %w[google_oauth2 twitter2 facebook]
    all_providers - connected
  end
end
