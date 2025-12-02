require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      name: "Test User",
      email_verified: true
    )
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    duplicate_user = User.new(email: @user.email, name: "Duplicate")
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should normalize email to lowercase" do
    user = User.create!(email: "NORMALIZE@EXAMPLE.COM", name: "Test", email_verified: true)
    assert_equal "normalize@example.com", user.email
  end

  test "should validate avatar_url format when present" do
    @user.avatar_url = "not a url"
    assert_not @user.valid?
    assert_includes @user.errors[:avatar_url], "is invalid"
  end

  test "should accept valid avatar_url" do
    @user.avatar_url = "https://example.com/avatar.jpg"
    assert @user.valid?
  end

  test "should accept nil avatar_url" do
    @user.avatar_url = nil
    assert @user.valid?
  end

  test "should have many oauth_identities" do
    assert_respond_to @user, :oauth_identities
  end

  test "should destroy oauth_identities when user is destroyed" do
    identity = @user.oauth_identities.create!(
      provider: "google_oauth2",
      uid: "12345",
      access_token: "token"
    )

    assert_difference "OauthIdentity.count", -1 do
      @user.destroy
    end
  end

  test "from_omniauth should find existing user by email when verified" do
    auth = mock_omniauth_auth(email: @user.email, email_verified: true)
    result = OauthAuthenticationService.new(auth).call

    assert result.success
    assert_equal @user.id, result.user.id
  end

  test "from_omniauth should create new user when email not found" do
    auth = mock_omniauth_auth(email: "new@example.com")

    assert_difference "User.count", 1 do
      result = OauthAuthenticationService.new(auth).call
      assert result.success
      assert_equal "new@example.com", result.user.email
      assert_equal "John Doe", result.user.name
      assert result.user.email_verified
    end
  end

  test "from_omniauth should not link account when email unverified" do
    @user.update!(email_verified: false)
    auth = mock_omniauth_auth(email: @user.email, email_verified: false)

    result = OauthAuthenticationService.new(auth).call
    assert_not result.success
    assert_equal :email_conflict, result.error_type
  end

  test "from_omniauth should link identity to existing user with verified email" do
    auth = mock_omniauth_auth(
      email: @user.email,
      name: "Updated Name",
      picture: "https://example.com/new.jpg",
      email_verified: true
    )

    assert_difference "OauthIdentity.count", 1 do
      result = OauthAuthenticationService.new(auth).call
      assert result.success
      assert_equal @user.id, result.user.id
    end
  end

  private

  def mock_omniauth_auth(email: "test@example.com", name: "John Doe",
                         picture: "https://example.com/pic.jpg",
                         email_verified: true)
    OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "123456",
      info: {
        email: email,
        name: name,
        image: picture,
        email_verified: email_verified
      },
      credentials: {
        token: "access_token",
        refresh_token: "refresh_token",
        expires_at: 1.hour.from_now.to_i
      },
      extra: {
        raw_info: {
          email: email,
          email_verified: email_verified,
          locale: "en"
        }
      }
    })
  end
end
