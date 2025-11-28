require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "test@example.com",
      name: "Test User",
      email_verified: true
    )

    @session = @user.sessions.create!(
      user_agent: "Test Browser",
      ip_address: "127.0.0.1"
    )
  end

  test "should get new sign in page" do
    get sign_in_url
    assert_response :success
    # Should not have password fields since we're OAuth-only
    assert_select "input[type=password]", count: 0
  end

  test "should get sessions index when authenticated" do
    sign_in_as(@user)
    get sessions_url
    assert_response :success
  end

  test "should require authentication to access sessions index" do
    get sessions_url
    assert_redirected_to sign_in_path
  end

  test "should destroy session when authenticated" do
    # Create a second session to delete (different from setup session and auth session)
    session_to_delete = @user.sessions.create!(
      user_agent: "Session To Delete",
      ip_address: "127.0.0.99"
    )

    sign_in_as(@user)
    delete session_url(session_to_delete)

    # Verify the session_to_delete was actually deleted
    assert_nil Session.find_by(id: session_to_delete.id)
    assert_redirected_to sign_in_path
    assert_equal "Signed out successfully", flash[:notice]
  end

  test "should require authentication to destroy session" do
    initial_count = Session.count

    delete session_url(@session)

    assert_equal initial_count, Session.count
    assert_redirected_to sign_in_path
  end

  test "should only allow user to destroy their own sessions" do
    other_user = User.create!(
      email: "other@example.com",
      name: "Other User",
      email_verified: true
    )

    other_session = other_user.sessions.create!(
      user_agent: "Other Browser",
      ip_address: "127.0.0.3"
    )

    # Sign in as @user but try to delete another user's session
    sign_in_as(@user)
    delete session_url(other_session)

    # Should get 404 Not Found
    assert_response :not_found

    # Verify the other user's session was not deleted
    assert_not_nil Session.find_by(id: other_session.id)
  end
end
