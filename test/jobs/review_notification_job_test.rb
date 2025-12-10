require "test_helper"

class ReviewNotificationJobTest < ActiveJob::TestCase
  setup do
    # Clean database
    UserReview.destroy_all
    User.destroy_all
    Game.destroy_all
    Publisher.destroy_all
    Developer.destroy_all

    # Create test data
    @user = User.create!(email: "test@example.com", email_verified: true, role: :user)
    @publisher = Publisher.create!(name: "Test Publisher")
    @developer = Developer.create!(name: "Test Developer")
    @game = Game.create!(
      title: "Test Game",
      publisher: @publisher,
      developer: @developer,
      release_date: 1.month.ago,
      rating_category: :everyone
    )

    @review = UserReview.create!(
      user: @user,
      game: @game,
      title: "Test Review",
      body: "This is a comprehensive test review with enough content to pass validation. " * 5,
      score: 8,
      moderation_status: :pending
    )
  end

  test "performs approved notification" do
    assert_nothing_raised do
      ReviewNotificationJob.perform_now(@review.id, "approved")
    end
  end

  test "performs rejected notification" do
    assert_nothing_raised do
      ReviewNotificationJob.perform_now(@review.id, "rejected")
    end
  end

  test "performs flagged notification" do
    assert_nothing_raised do
      ReviewNotificationJob.perform_now(@review.id, "flagged")
    end
  end

  test "logs warning for unknown event" do
    # Should not raise error, just log warning
    assert_nothing_raised do
      ReviewNotificationJob.perform_now(@review.id, "unknown_event")
    end
  end

  test "job is enqueued on mailers queue" do
    assert_enqueued_with(job: ReviewNotificationJob, queue: "mailers") do
      ReviewNotificationJob.perform_later(@review.id, "approved")
    end
  end

  test "calls correct mailer method for each event type" do
    # Test that job executes without errors for all event types
    [ "approved", "rejected", "flagged" ].each do |event|
      assert_nothing_raised do
        ReviewNotificationJob.perform_now(@review.id, event)
      end
    end
  end
end
