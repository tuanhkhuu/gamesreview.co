require "test_helper"

class ReviewAutoApprovalJobTest < ActiveJob::TestCase
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
  end

  test "auto-approves pending reviews older than 7 days" do
    old_review = UserReview.create!(
      user: @user,
      game: @game,
      title: "Old Review",
      body: "This is a test review that is old enough to be auto-approved. " * 5,
      score: 8,
      moderation_status: :pending,
      created_at: 8.days.ago
    )

    ReviewAutoApprovalJob.perform_now

    assert_equal "approved", old_review.reload.moderation_status
  end

  test "does not auto-approve pending reviews younger than 7 days" do
    recent_review = UserReview.create!(
      user: @user,
      game: @game,
      title: "Recent Review",
      body: "This is a recent test review that should not be auto-approved. " * 5,
      score: 7,
      moderation_status: :pending,
      created_at: 5.days.ago
    )

    ReviewAutoApprovalJob.perform_now

    assert_equal "pending", recent_review.reload.moderation_status
  end

  test "does not affect already approved reviews" do
    approved_review = UserReview.create!(
      user: @user,
      game: @game,
      title: "Approved Review",
      body: "This review is already approved and should remain unchanged. " * 5,
      score: 9,
      moderation_status: :approved,
      created_at: 10.days.ago
    )

    ReviewAutoApprovalJob.perform_now

    assert_equal "approved", approved_review.reload.moderation_status
  end

  test "does not affect flagged reviews" do
    flagged_review = UserReview.create!(
      user: @user,
      game: @game,
      title: "Flagged Review",
      body: "This review is flagged and should not be auto-approved. " * 5,
      score: 6,
      moderation_status: :flagged,
      created_at: 15.days.ago
    )

    ReviewAutoApprovalJob.perform_now

    assert_equal "flagged", flagged_review.reload.moderation_status
  end

  test "does not affect rejected reviews" do
    rejected_review = UserReview.create!(
      user: @user,
      game: @game,
      title: "Rejected Review",
      body: "This review was rejected and should not be auto-approved. " * 5,
      score: 5,
      moderation_status: :rejected,
      created_at: 20.days.ago
    )

    ReviewAutoApprovalJob.perform_now

    assert_equal "rejected", rejected_review.reload.moderation_status
  end

  test "auto-approves multiple eligible reviews" do
    review1 = UserReview.create!(
      user: @user,
      game: @game,
      title: "Review 1",
      body: "First old pending review for auto-approval testing. " * 5,
      score: 8,
      moderation_status: :pending,
      created_at: 8.days.ago
    )

    user2 = User.create!(email: "user2@example.com", email_verified: true, role: :user)
    review2 = UserReview.create!(
      user: user2,
      game: @game,
      title: "Review 2",
      body: "Second old pending review for auto-approval testing. " * 5,
      score: 7,
      moderation_status: :pending,
      created_at: 10.days.ago
    )

    ReviewAutoApprovalJob.perform_now

    assert_equal "approved", review1.reload.moderation_status
    assert_equal "approved", review2.reload.moderation_status
  end

  test "job is enqueued on background queue" do
    assert_enqueued_with(job: ReviewAutoApprovalJob, queue: "background") do
      ReviewAutoApprovalJob.perform_later
    end
  end
end
