require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get terms page" do
    get terms_url
    assert_response :success
    assert_select "h1", "Terms of Service"
  end

  test "should get privacy page" do
    get privacy_url
    assert_response :success
    assert_select "h1", "Privacy Policy"
  end

  test "terms page should have link back to sign in" do
    get terms_url
    assert_response :success
    assert_select "a[href=?]", sign_in_path
  end

  test "privacy page should have link back to sign in" do
    get privacy_url
    assert_response :success
    assert_select "a[href=?]", sign_in_path
  end
end
