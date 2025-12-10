require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  setup do
    # Clean database
    User.destroy_all

    @user = User.create!(
      email: "test@example.com",
      email_verified: true,
      role: :user
    )
  end

  test "welcome_email sends to user email" do
    email = UserMailer.welcome_email(@user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email ], email.to
    assert_equal "Welcome to GamesReview.com!", email.subject
    assert_match "Thank you for joining GamesReview.com", email.body.encoded
  end

  test "welcome_email includes user name from email" do
    email = UserMailer.welcome_email(@user)

    # User email is test@example.com, so first part capitalized is "Test"
    assert_match "Hello Test!", email.body.encoded
  end

  test "welcome_email includes login URL" do
    email = UserMailer.welcome_email(@user)

    assert_match "Start Exploring Games", email.body.encoded
  end

  test "welcome_email has both HTML and text parts" do
    email = UserMailer.welcome_email(@user)

    assert email.html_part.present?
    assert email.text_part.present?
  end

  test "email_verified sends notification" do
    email = UserMailer.email_verified(@user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email ], email.to
    assert_equal "Email Verified - Your GamesReview.com Account is Ready", email.subject
  end

  test "email_verified includes content about verification" do
    email = UserMailer.email_verified(@user)

    assert_match "verified", email.body.encoded.downcase
  end
end
