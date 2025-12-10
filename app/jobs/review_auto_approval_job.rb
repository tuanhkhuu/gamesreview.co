# Background job to automatically approve user reviews that meet certain criteria
# Reviews that have been pending for 7+ days with no flags are auto-approved
class ReviewAutoApprovalJob < ApplicationJob
  queue_as :background

  PENDING_THRESHOLD_DAYS = 7

  def perform
    auto_approve_eligible_reviews
  end

  private

  def auto_approve_eligible_reviews
    eligible_reviews = UserReview
      .where(moderation_status: :pending)
      .where("created_at <= ?", PENDING_THRESHOLD_DAYS.days.ago)

    approved_count = 0

    eligible_reviews.find_each do |review|
      if review.update(moderation_status: :approved)
        approved_count += 1
        # Could enqueue a notification job here
        # ReviewNotificationMailer.review_approved(review).deliver_later
      end
    end

    Rails.logger.info "Auto-approved #{approved_count} user reviews"
  end
end
