class User < ApplicationRecord
  # OAuth-only authentication - no password
  # has_secure_password removed

  has_many :sessions, dependent: :destroy
  has_many :oauth_identities, dependent: :destroy

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :avatar_url, format: {
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    allow_blank: true
  }

  normalizes :email, with: -> { _1.strip.downcase }

  # Find or create user from OAuth provider data
  def self.from_omniauth(auth_hash)
    # Delegate to service object for complex logic
    result = OauthAuthenticationService.new(auth_hash).call
    result.success ? result.user : nil
  end
end
