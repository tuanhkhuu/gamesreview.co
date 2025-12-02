# OAuth Authentication Feature

**Date**: November 27, 2025  
**Status**: Planned  
**Type**: Authentication System

## Overview

This feature implements passwordless OAuth-only authentication for the Games Review platform. Users can sign in and sign up using their Google, Twitter, or Facebook accounts without needing to create or remember passwords.

## User Stories

- As a new user, I can sign up using my Google/Twitter/Facebook account so that I don't need to create another password
- As a returning user, I can sign in with any of my connected OAuth providers for quick access
- As a user, I can connect multiple OAuth providers to my account so that I have flexible sign-in options
- As a user, I can disconnect OAuth providers (as long as I keep at least one) to manage my account security
- As a user, I can see which OAuth accounts are connected to my profile

## Technical Implementation

### Architecture

```
┌─────────────────┐
│      User       │
│  (Core Model)   │
│                 │
│ - email         │
│ - name          │
│ - avatar_url    │
│ - email_verified│
└────────┬────────┘
         │
         │ has_many
         │
         ▼
┌─────────────────┐
│    Identity     │
│ (OAuth Data)    │
│                 │
│ - provider      │
│ - uid           │
│ - access_token  │
│ - refresh_token │
│ - expires_at    │
│ - raw_info      │
└─────────────────┘
```

### Models

#### User Model

**Purpose**: Represents a user account in the system

**Key Attributes**:

- `email` (string, required, unique): User's email from OAuth provider
- `email_verified` (boolean, default: false, indexed): Email verification status
- `name` (string): Display name from OAuth profile
- `avatar_url` (string, validated): Profile picture URL from OAuth provider

**Associations**:

- `has_many :identities, dependent: :destroy`

**Key Methods**:

- `User.from_omniauth(auth_hash)`: Creates or finds user from OAuth data

**Business Rules**:

- Email must be unique across all users
- User must have at least one identity to authenticate
- No password field (OAuth-only authentication)

**Validations**:

```ruby
class User < ApplicationRecord
  has_many :identities, dependent: :destroy

  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :avatar_url, format: {
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    allow_blank: true
  }

  # Normalize email before save
  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
```

#### Identity Model

**Purpose**: Stores OAuth provider connection data for users

**Key Attributes**:

- `user_id` (integer, required): Reference to user
- `provider` (string, required): OAuth provider name ('google', 'twitter', 'facebook')
- `uid` (string, required): Provider's unique user identifier
- `access_token` (text, encrypted): OAuth access token
- `refresh_token` (text, encrypted): OAuth refresh token (if applicable)
- `expires_at` (datetime): Token expiration time
- `raw_info` (jsonb): Additional provider profile data (locale, picture URLs, follower counts, etc.)

**Associations**:

- `belongs_to :user`

**Validations**:

- Provider and UID must be present
- UID must be unique per provider (composite unique constraint)

**Security**:

- Access tokens and refresh tokens MUST be encrypted using Rails 7+ `encrypts` or attr_encrypted gem

**Implementation Example**:

```ruby
class Identity < ApplicationRecord
  belongs_to :user

  # Token encryption (Rails 7+)
  encrypts :access_token
  encrypts :refresh_token

  # Or for Rails < 7, use attr_encrypted gem
  # attr_encrypted :access_token, key: Rails.application.credentials.encryption_key
  # attr_encrypted :refresh_token, key: Rails.application.credentials.encryption_key

  validates :provider, :uid, presence: true
  validates :uid, uniqueness: { scope: :provider }

  # Audit logging for security
  after_create :log_provider_connected
  after_destroy :log_provider_disconnected

  private

  def log_provider_connected
    Rails.logger.info "[SECURITY] User #{user_id} connected #{provider} identity"
  end

  def log_provider_disconnected
    Rails.logger.info "[SECURITY] User #{user_id} disconnected #{provider} identity"
  end
end
```

**Indexes**:

- `[provider, uid]` (unique)
- `provider` (for filtering)
- `user_id` (foreign key)

### Database Schema

```sql
-- Users table
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR NOT NULL UNIQUE,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  name VARCHAR,
  avatar_url VARCHAR,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX index_users_on_email ON users(email);

-- Identities table
CREATE TABLE identities (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider VARCHAR NOT NULL,
  uid VARCHAR NOT NULL,
  access_token TEXT,
  refresh_token TEXT,
  expires_at TIMESTAMP,
  raw_info JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX index_identities_on_user_id ON identities(user_id);
CREATE INDEX index_identities_on_provider ON identities(provider);
CREATE UNIQUE INDEX index_identities_on_provider_and_uid ON identities(provider, uid);

-- Optional: Add index on email_verified if filtering by verification status
CREATE INDEX index_users_on_email_verified ON users(email_verified);
```

### OAuth Flow

```
1. User clicks "Sign in with Google"
   │
   ▼
2. Redirect to Google OAuth
   │
   ▼
3. User authorizes app
   │
   ▼
4. Google redirects to callback URL with auth code
   │
   ▼
5. OmniAuth exchanges code for tokens
   │
   ▼
6. OmniauthCallbacksController receives auth hash
   │
   ▼
7. Find or create User + Identity
   │
   ▼
8. Create session
   │
   ▼
9. Redirect to dashboard
```

### Controllers

#### OmniauthCallbacksController

**Purpose**: Handles OAuth provider callbacks

**Actions**:

- `create`: Process OAuth callback, create/find user, establish session
- `failure`: Handle OAuth errors gracefully

**Security**:

- CSRF protection via omniauth-rails_csrf_protection gem
- State parameter validation (handled by OmniAuth)

#### SessionsController

**Purpose**: Manages user sessions

**Actions**:

- `new`: Display OAuth provider sign-in buttons
- `destroy`: Log out user and clear session

#### IdentitiesController

**Purpose**: Manage connected OAuth accounts

**Actions**:

- `index`: View all connected providers
- `create`: Connect additional OAuth provider
- `destroy`: Disconnect provider (prevent if last identity)

**Authorization**:

- All actions require authentication
- Users can only manage their own identities

### Routes

```ruby
# OAuth authentication
get  "sign_in", to: "sessions#new"
delete "sign_out", to: "sessions#destroy"

# OAuth callbacks
get "/auth/:provider/callback", to: "omniauth_callbacks#create"
get "/auth/failure", to: "omniauth_callbacks#failure"

# Connected accounts
resources :identities, only: [:index, :create, :destroy]
```

### Service Objects

#### OauthAuthenticationService

**Purpose**: Encapsulates OAuth authentication logic

**Responsibilities**:

- Find or create user from OAuth data
- Create or update identity record
- Extract and normalize profile data from different providers
- Handle edge cases (existing email with different provider)
- Handle account linking scenarios

**Usage**:

```ruby
result = OauthAuthenticationService.new(auth_hash).call

if result.success?
  user = result.user
  identity = result.identity
  new_user = result.new_user
else
  error = result.error
  error_type = result.error_type # :email_conflict, :validation_error, etc.
end
```

**Implementation Example**:

```ruby
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
    identity = Identity.find_by(provider: @provider, uid: @uid)
    return success_result(identity.user, identity, false) if identity

    # Check for existing user with same email (ACCOUNT LINKING SCENARIO)
    existing_user = User.find_by(email: @email)

    if existing_user
      # SECURITY DECISION: Auto-link if email is verified from OAuth provider
      # Alternative: Require manual verification step
      if @auth_hash.info.email_verified
        identity = existing_user.identities.create!(
          provider: @provider,
          uid: @uid,
          access_token: @auth_hash.credentials.token,
          refresh_token: @auth_hash.credentials.refresh_token,
          expires_at: Time.at(@auth_hash.credentials.expires_at),
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
      email_verified: @auth_hash.info.email_verified || false,
      name: @auth_hash.info.name,
      avatar_url: @auth_hash.info.image
    )

    identity = user.identities.create!(
      provider: @provider,
      uid: @uid,
      access_token: @auth_hash.credentials.token,
      refresh_token: @auth_hash.credentials.refresh_token,
      expires_at: Time.at(@auth_hash.credentials.expires_at),
      raw_info: extract_raw_info
    )

    success_result(user, identity, true)

  rescue ActiveRecord::RecordInvalid => e
    error_result(:validation_error, e.message)
  rescue StandardError => e
    Rails.logger.error "[OAuth] Authentication failed: #{e.message}"
    error_result(:unknown_error, "Authentication failed. Please try again.")
  end

  private

  def extract_raw_info
    case @provider
    when 'google_oauth2'
      {
        picture_url: @auth_hash.info.image,
        locale: @auth_hash.extra.raw_info.locale,
        verified_email: @auth_hash.extra.raw_info.verified_email
      }
    when 'twitter2'
      {
        username: @auth_hash.info.nickname,
        profile_image_url: @auth_hash.info.image
      }
    when 'facebook'
      {
        picture_url: @auth_hash.info.image,
        locale: @auth_hash.extra.raw_info.locale
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
```

**Account Linking Strategy**:

- **Scenario**: User has account with Google (user@gmail.com), tries to sign in with Facebook using same email
- **Solution**: Auto-link if email is verified by OAuth provider
- **Security**: Only link if `email_verified` is true from OAuth provider
- **Alternative**: Require email verification step for extra security
- **User Experience**: User sees message "Facebook account connected to your existing account"

## OAuth Provider Configuration

### Google OAuth 2.0

- **Scope**: `email`, `profile`
- **Profile Data**: Email, name, profile picture
- **Token Refresh**: Yes (long-lived refresh tokens)

### Twitter OAuth 2.0

- **Scope**: `tweet.read`, `users.read`
- **Profile Data**: Email (requires approval), username, profile picture
- **Token Refresh**: Yes

⚠️ **CRITICAL TWITTER REQUIREMENT**:

- Email access requires **manual approval** from Twitter Developer Portal
- Approval can take **1-7 business days**
- **Action Required BEFORE Development**: Apply for email permission immediately
- **Fallback Strategy**: Use Twitter username as identifier if email not available
- **Recommendation**: Implement Google and Facebook OAuth first, add Twitter after approval

### Facebook OAuth

- **Scope**: `email`, `public_profile`
- **Info Fields**: `email`, `name`, `picture`
- **Token Refresh**: Long-lived tokens (60 days)

## Setup & Configuration

### Environment Variables

**Option 1: Environment Variables (.env file for development)**

```bash
# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Twitter OAuth 2.0
TWITTER_CLIENT_ID=your_twitter_client_id
TWITTER_CLIENT_SECRET=your_twitter_client_secret

# Facebook OAuth
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret
```

**Option 2: Rails Credentials (recommended for production)**

```bash
# Edit credentials
RAILS_ENV=production rails credentials:edit

# Add to credentials file:
oauth:
  google:
    client_id: your_google_client_id
    client_secret: your_google_client_secret
  twitter:
    client_id: your_twitter_client_id
    client_secret: your_twitter_client_secret
  facebook:
    app_id: your_facebook_app_id
    app_secret: your_facebook_app_secret
```

**Access in code**:

```ruby
# config/initializers/omniauth.rb
provider :google_oauth2,
  Rails.application.credentials.dig(:oauth, :google, :client_id) || ENV['GOOGLE_CLIENT_ID'],
  Rails.application.credentials.dig(:oauth, :google, :client_secret) || ENV['GOOGLE_CLIENT_SECRET']
```

### OAuth Application Setup

#### Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URIs:
   - Development: `http://localhost:3000/auth/google_oauth2/callback`
   - Production: `https://yourdomain.com/auth/google_oauth2/callback`

#### Twitter Developer Portal

1. Go to [Twitter Developer Portal](https://developer.twitter.com/)
2. Create a new app
3. Enable OAuth 2.0
4. Add callback URLs:
   - Development: `http://localhost:3000/auth/twitter2/callback`
   - Production: `https://yourdomain.com/auth/twitter2/callback`
5. Request email permission (requires approval)

#### Facebook Developers

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app (Consumer type)
3. Add Facebook Login product
4. Configure OAuth redirect URIs:
   - Development: `http://localhost:3000/auth/facebook/callback`
   - Production: `https://yourdomain.com/auth/facebook/callback`
5. Make app public when ready for production

### Database Setup

```bash
# Install Authentication Zero first
rails generate authentication

# Customize User model (remove password fields, add OAuth fields)
# Then generate Identity model
rails generate model Identity user:references provider:string uid:string access_token:text refresh_token:text expires_at:datetime raw_info:jsonb

# Add indexes in migration
# db/migrate/XXXXXX_create_identities.rb:
# add_index :identities, [:provider, :uid], unique: true
# add_index :identities, :provider

# Optional: Add email_verified index to users
# rails generate migration AddEmailVerifiedIndexToUsers
# add_index :users, :email_verified

# Run migrations
rails db:migrate
```

## Authorization Rules

- **Public**: Sign in page, OAuth callbacks
- **Authenticated Users**: Dashboard, profile, connected accounts
- **Account Management**: Users can only manage their own identities
- **Deletion Prevention**: Cannot delete last identity (would lock user out)

## Business Rules

1. **Email Uniqueness**: One email = one user account
2. **Multi-Provider Support**: Users can connect multiple OAuth providers
3. **Minimum Identity**: User must always have at least one connected identity
4. **Email Verification**: Marked as verified when from OAuth provider
5. **Profile Sync**: Name and avatar updated from most recently used OAuth provider

## Testing

### Test Coverage

✅ **Model Tests**:

- User email validation and uniqueness
- Identity provider/uid uniqueness
- User-Identity associations
- User.from_omniauth creates users correctly

✅ **Controller Tests**:

- OAuth callback creates new users
- OAuth callback finds existing users
- Session creation on successful auth
- Identity connection/disconnection
- Authorization checks

✅ **System Tests**:

- Complete OAuth flow for each provider (mocked)
- User can connect multiple providers
- User can disconnect providers
- Sign out functionality

### Running Tests

```bash
# All authentication tests
rails test:system test/system/authentication_test.rb

# Model tests
rails test test/models/user_test.rb
rails test test/models/identity_test.rb

# Controller tests
rails test test/controllers/omniauth_callbacks_controller_test.rb
rails test test/controllers/identities_controller_test.rb
```

## Performance Considerations

### Database Optimizations

- Unique index on `identities[provider, uid]` for fast lookups
- Index on `users.email` for authentication queries
- JSONB column for flexible provider data storage
- Foreign key indexes for association queries

### Caching Strategy

- Cache user's connected providers list (invalidate on identity changes)
- Cache OAuth provider configurations (static data)

### Token Management

- Refresh tokens stored for automatic renewal
- Expired tokens trigger re-authentication flow
- Background job for token refresh (future enhancement)

## Security Considerations

### Authentication Security

- ✅ CSRF protection on OAuth callbacks
- ✅ State parameter validation (OmniAuth)
- ✅ Secure session storage
- ✅ HTTPS required in production

### Data Protection

- ✅ OAuth tokens encrypted at rest (use Rails encrypted attributes)
- ✅ No password storage (passwordless design)
- ✅ Minimal data storage (only what's needed)
- ✅ Secure token transmission

### Session Security

- Session timeout after inactivity (2 weeks)
- Secure cookie flags (httponly, secure, samesite)
- Session fixation prevention
- CSRF token rotation

**Session Configuration**:

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_gamesreview_session',
  expire_after: 2.weeks,  # Session timeout
  secure: Rails.env.production?,  # HTTPS only in production
  httponly: true,  # Prevent JavaScript access
  same_site: :lax  # CSRF protection
```

## Troubleshooting

### Common Issues

#### "Redirect URI mismatch"

**Cause**: OAuth callback URL doesn't match provider configuration  
**Solution**:

- Verify exact URL in provider console
- Check for http vs https
- Ensure port numbers match (localhost:3000)

#### "Invalid credentials"

**Cause**: Wrong client ID or secret  
**Solution**:

- Verify environment variables are set correctly
- Check for trailing spaces in credentials
- Ensure OAuth app is enabled in provider console

#### "Email already taken"

**Cause**: User previously signed up with different provider  
**Solution**: Automatic account linking (if email verified)

**How it works**:

1. User signs up with Google (email: user@example.com)
2. Later tries to sign in with Facebook (same email)
3. System detects existing email
4. If Facebook email is verified, automatically links Facebook identity to existing account
5. User can now sign in with either Google or Facebook
6. User sees flash message: "Facebook account connected to your existing account"

**Security Note**: Only auto-links if `email_verified` is true from OAuth provider. This prevents email hijacking attacks.

**Manual Override**: Users can also manually connect additional providers from Settings → Connected Accounts

#### "Cannot disconnect provider"

**Cause**: Attempting to remove last identity  
**Solution**: User must connect another provider first before disconnecting

#### OAuth callback not working locally

**Cause**: Missing callback URL configuration  
**Solution**: Add `http://localhost:3000/auth/[provider]/callback` to provider's allowed URLs

## Future Enhancements

### Planned Features

- [x] **Account Linking**: Connect different OAuth providers to existing account (IMPLEMENTED - auto-links on verified email match)
- [ ] **Email Change Workflow**: Handle email changes when user has multiple identities
- [ ] **Profile Data Sync**: Regular sync of name/avatar from OAuth providers
- [ ] **Two-Factor Authentication**: Additional security layer even with OAuth
- [ ] **Magic Link Fallback**: Email-based passwordless login as backup
- [ ] **Additional Providers**: GitHub, Microsoft, Apple Sign In
- [ ] **Remember Device**: Reduce re-authentication frequency
- [ ] **Session Management UI**: View and revoke active sessions
- [ ] **Token Refresh Automation**: Background job to refresh expiring tokens
- [ ] **Audit Log**: Track authentication events and provider connections

### Technical Improvements

- [ ] Token encryption with Rails 7+ encrypted attributes
- [ ] Rate limiting on OAuth endpoints
- [ ] Advanced session management (multiple active sessions)
- [ ] OAuth scope management (request minimal scopes)

## Deployment Checklist

### Pre-Deployment

- [ ] Twitter email permission approved (if using Twitter)
- [ ] OAuth apps created and configured in all providers
- [ ] Callback URLs updated for production domain
- [ ] Token encryption configured (Rails credentials encryption key set)
- [ ] Session timeout configured (2 weeks default)

### Deployment

- [ ] Environment variables set in production (or Rails credentials configured)
- [ ] HTTPS enabled and enforced
- [ ] Database migrations run
- [ ] Seeds updated (if applicable)
- [ ] Error tracking configured (Sentry, etc.)

### Post-Deployment

- [ ] OAuth flow tested in production for each provider
- [ ] Account linking tested (same email, different providers)
- [ ] Session configuration reviewed (timeout, secure flags)
- [ ] Security headers configured (CSP, etc.)
- [ ] Rate limiting enabled on OAuth endpoints
- [ ] Security audit logging enabled

## Rollback Plan

If issues arise after deployment:

1. **Quick Disable**: Comment out OAuth routes to prevent new sign-ins
2. **Session Preservation**: Existing sessions continue to work
3. **Database Rollback**: Migrations are reversible
   ```bash
   rails db:rollback STEP=2  # Rollback identities and user tables
   ```
4. **Gem Removal**: Remove OAuth gems from Gemfile if needed
5. **Revert Code**: Git revert to previous authentication system

## Related Documentation

- [API Documentation](../api/20251127_oauth_endpoints.md)
- [Setup Guide](../../README.md#authentication)
- [Security Policy](../security/authentication_security.md)

## Changelog

### 2025-11-27 - Initial Planning

- Planned OAuth-only authentication system
- Designed multi-provider support architecture
- Created technical specifications
