# Service object to handle OAuth authentication logic
# Encapsulates user creation, identity management, and account linking
class OauthAuthenticationService
  Result = Struct.new(:success, :user, :identity, :new_user, :error, :error_type, keyword_init: true)

  def initialize(auth_hash)
    @auth_hash = auth_hash
    @provider = auth_hash.provider
    @uid = auth_hash.uid
    @email = auth_hash.info.email
  end

  def call
    # Try to find existing identity first
    identity = OauthIdentity.find_by(provider: @provider, uid: @uid)
    return success_result(identity.user, identity, false) if identity

    # Check for existing user with same email (ACCOUNT LINKING SCENARIO)
    existing_user = User.find_by(email: @email)

    if existing_user
      # SECURITY DECISION: Auto-link if email is verified from OAuth provider
      # This prevents email hijacking while providing seamless account linking
      if email_verified?
        identity = existing_user.oauth_identities.create!(
          provider: @provider,
          uid: @uid,
          access_token: @auth_hash.credentials.token,
          refresh_token: @auth_hash.credentials.refresh_token,
          expires_at: token_expires_at,
          raw_info: extract_raw_info
        )
        return success_result(existing_user, identity, false)
      else
        return error_result(
          :email_conflict,
          "An account with email #{@email} already exists. Please sign in with your original provider."
        )
      end
    end

    # Create new user + identity
    user = User.create!(
      email: @email,
      email_verified: email_verified?,
      name: @auth_hash.info.name,
      avatar_url: @auth_hash.info.image
    )

    identity = user.oauth_identities.create!(
      provider: @provider,
      uid: @uid,
      access_token: @auth_hash.credentials.token,
      refresh_token: @auth_hash.credentials.refresh_token,
      expires_at: token_expires_at,
      raw_info: extract_raw_info
    )

    success_result(user, identity, true)

  rescue ActiveRecord::RecordInvalid => e
    error_result(:validation_error, e.message)
  rescue StandardError => e
    Rails.logger.error "[OAuth] Authentication failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    error_result(:unknown_error, "Authentication failed. Please try again.")
  end

  private

  def email_verified?
    # Check if email is verified by the OAuth provider
    case @provider
    when "google_oauth2"
      @auth_hash.extra.raw_info.email_verified == true
    when "facebook"
      # Facebook emails are verified by default
      true
    when "twitter2"
      # Twitter emails require approval and are considered verified
      @email.present?
    else
      false
    end
  end

  def token_expires_at
    return nil unless @auth_hash.credentials.expires_at
    Time.at(@auth_hash.credentials.expires_at)
  end

  def extract_raw_info
    case @provider
    when "google_oauth2"
      {
        picture_url: @auth_hash.info.image,
        locale: @auth_hash.extra.raw_info.locale,
        verified_email: @auth_hash.extra.raw_info.verified_email
      }
    when "twitter2"
      {
        username: @auth_hash.info.nickname,
        profile_image_url: @auth_hash.info.image,
        description: @auth_hash.info.description
      }
    when "facebook"
      {
        picture_url: @auth_hash.info.image,
        locale: @auth_hash.extra.raw_info.locale,
        link: @auth_hash.extra.raw_info.link
      }
    else
      {}
    end
  end

  def success_result(user, identity, new_user)
    Result.new(success: true, user: user, identity: identity, new_user: new_user)
  end

  def error_result(error_type, message)
    Result.new(success: false, error: message, error_type: error_type)
  end
end
