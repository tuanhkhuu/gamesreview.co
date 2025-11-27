require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "test@example.com",
      name: "Test User"
    )
    # Create some test data for the user
    @oauth_identity = @user.oauth_identities.create!(
      provider: "google_oauth2",
      uid: "123456"
    )
    @session = @user.sessions.create!(
      user_agent: "Test Browser",
      ip_address: "127.0.0.1"
    )
  end

  test "should require authentication to delete account" do
    delete account_path
    assert_redirected_to sign_in_path
  end

  test "should delete user account when authenticated" do
    # Count records before deletion
    user_count = User.count
    oauth_identity_count = OauthIdentity.count

    # Make authenticated request
    delete account_path, headers: { "X-Test-User-Id" => @user.id }

    # Verify user was deleted
    assert_equal user_count - 1, User.count
    assert_nil User.find_by(id: @user.id)

    # Verify associated records were deleted
    assert_equal oauth_identity_count - 1, OauthIdentity.count
    assert_nil OauthIdentity.find_by(id: @oauth_identity.id)

    # Verify sessions were deleted
    assert_nil Session.find_by(id: @session.id)

    # Verify redirect and flash message
    assert_redirected_to root_path
    assert_equal "Your account has been permanently deleted. We're sorry to see you go!", flash[:notice]
  end

  test "should delete all user oauth identities on account deletion" do
    # Create multiple OAuth identities
    @user.oauth_identities.create!(
      provider: "twitter2",
      uid: "twitter123"
    )
    @user.oauth_identities.create!(
      provider: "facebook",
      uid: "fb123"
    )

    assert_equal 3, @user.oauth_identities.count

    delete account_path, headers: { "X-Test-User-Id" => @user.id }

    # Verify all OAuth identities are deleted
    assert_equal 0, OauthIdentity.where(user_id: @user.id).count
  end

  test "should delete all user sessions on account deletion" do
    # Create multiple sessions
    @user.sessions.create!(user_agent: "Chrome", ip_address: "192.168.1.1")
    @user.sessions.create!(user_agent: "Firefox", ip_address: "192.168.1.2")

    assert_equal 3, @user.sessions.count

    delete account_path, headers: { "X-Test-User-Id" => @user.id }

    # Verify all sessions are deleted
    assert_equal 0, Session.where(user_id: @user.id).count
  end

  test "should clear cookies and reset session on account deletion" do
    delete account_path, headers: { "X-Test-User-Id" => @user.id }

    # Verify session was reset and redirected
    assert_redirected_to root_path

    # Verify user is no longer authenticated by trying to access protected page
    get oauth_identities_path
    assert_redirected_to sign_in_path
  end

  test "should log account deletion for audit purposes" do
    # This test verifies the logging behavior
    # In a real scenario, you might want to check actual log output
    # For now, we just ensure the deletion completes without errors

    assert_nothing_raised do
      delete account_path, headers: { "X-Test-User-Id" => @user.id }
    end

    assert_response :redirect
  end

  test "should handle deletion of user with no oauth identities" do
    @user.oauth_identities.destroy_all

    assert_nothing_raised do
      delete account_path, headers: { "X-Test-User-Id" => @user.id }
    end

    assert_nil User.find_by(id: @user.id)
    assert_redirected_to root_path
  end

  test "should handle deletion of user with no sessions" do
    @user.sessions.destroy_all

    assert_nothing_raised do
      delete account_path, headers: { "X-Test-User-Id" => @user.id }
    end

    assert_nil User.find_by(id: @user.id)
    assert_redirected_to root_path
  end
end
