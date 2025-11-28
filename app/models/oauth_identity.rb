# Represents an OAuth provider connection for a user.
# Stores provider-specific data and tokens.
# Each provider+uid combination is unique across the system.
#
# Associations:
#   - belongs_to :user
#
# Validations:
#   - uid must be unique per provider
#   - provider must be in SUPPORTED_PROVIDERS list
#
# Security:
#   - Access tokens and refresh tokens are encrypted at rest
class OauthIdentity < ApplicationRecord
  SUPPORTED_PROVIDERS = %w[google_oauth2 twitter2 facebook].freeze

  belongs_to :user

  # Token encryption (Rails 7+)
  encrypts :access_token, deterministic: false
  encrypts :refresh_token, deterministic: false

  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }
  validates :provider, inclusion: {
    in: SUPPORTED_PROVIDERS,
    message: "%{value} is not a supported OAuth provider"
  }

  # Audit logging for security
  after_create :log_provider_connected
  after_destroy :log_provider_disconnected

  # Scopes
  scope :for_provider, ->(provider) { where(provider: provider) }
  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  private

  def log_provider_connected
    Rails.logger.info "[SECURITY] User #{user_id} connected #{provider} identity"
  end

  def log_provider_disconnected
    Rails.logger.info "[SECURITY] User #{user_id} disconnected #{provider} identity"
  end
end
