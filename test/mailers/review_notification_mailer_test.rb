require "test_helper"

class ReviewNotificationMailerTest < ActionMailer::TestCase
  setup do
    # Clean database
    UserReview.destroy_all
    User.destroy_all
    Game.destroy_all
    Publisher.destroy_all
    Developer.destroy_all

    # Create test data
    @user = User.create!(email: "reviewer@example.com", email_verified: true, role: :user)
    @publisher = Publisher.create!(name: "Test Publisher")
    @developer = Developer.create!(name: "Test Developer")
    @game = Game.create!(
      title: "Epic Game Title",
      publisher: @publisher,
      developer: @developer,
      release_date: 1.month.ago,
      rating_category: :everyone
    )

    @review = UserReview.create!(
      user: @user,
      game: @game,
      title: "Amazing Game",
      body: "This is a comprehensive review with detailed feedback about the game experience. " * 5,
      score: 9,
      moderation_status: :pending
    )
  end

  test "review_approved sends email with correct subject" do
    email = ReviewNotificationMailer.review_approved(@review)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email ], email.to
    assert_includes email.subject, "Epic Game Title"
    assert_includes email.subject, "approved"
  end

  test "review_approved_includes_review_details" do
    email = ReviewNotificationMailer.review_approved(@review)

    assert_match @review.title, email.body.encoded
    assert_match @game.title, email.body.encoded
    # Score is stored as decimal (9.0) so match either format
    assert_match /9(\.0)?\/10/, email.body.encoded
  end

  test "review_approved has both HTML and text parts" do
    email = ReviewNotificationMailer.review_approved(@review)

    assert email.html_part.present?
    assert email.text_part.present?
  end

  test "review_rejected sends email with correct subject" do
    email = ReviewNotificationMailer.review_rejected(@review)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email ], email.to
    assert_includes email.subject, "Epic Game Title"
    assert_includes email.subject, "Status Update"
  end

  test "review_rejected_includes_guidelines_information" do
    email = ReviewNotificationMailer.review_rejected(@review)

    assert_match "did not meet our community guidelines", email.body.encoded
    # URL will be root_url in test environment (http://example.com/)
    assert_match "http://example.com", email.body.encoded
  end

  test "review_rejected lists common rejection reasons" do
    email = ReviewNotificationMailer.review_rejected(@review)

    assert_match "Inappropriate language", email.body.encoded
    assert_match "Spam or promotional", email.body.encoded
  end

  test "review_flagged sends email with correct subject" do
    email = ReviewNotificationMailer.review_flagged(@review)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email ], email.to
    assert_includes email.subject, "Epic Game Title"
    assert_includes email.subject, "attention"
  end

  test "review_flagged explains moderation process" do
    email = ReviewNotificationMailer.review_flagged(@review)

    assert_match "flagged for moderation", email.body.encoded
    assert_match "moderation team will review", email.body.encoded
  end

  test "all notification emails include game title" do
    emails = [
      ReviewNotificationMailer.review_approved(@review),
      ReviewNotificationMailer.review_rejected(@review),
      ReviewNotificationMailer.review_flagged(@review)
    ]

    emails.each do |email|
      assert_match @game.title, email.body.encoded
    end
  end

  test "all notification emails include user greeting" do
    emails = [
      ReviewNotificationMailer.review_approved(@review),
      ReviewNotificationMailer.review_rejected(@review),
      ReviewNotificationMailer.review_flagged(@review)
    ]

    # User email is reviewer@example.com, first part capitalized is "Reviewer"
    emails.each do |email|
      assert_match "Reviewer", email.body.encoded
    end
  end
end
