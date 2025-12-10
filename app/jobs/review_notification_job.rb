# Background job to send email notifications for review-related events
# Handles notifications for review approval, rejection, and flagging
class ReviewNotificationJob < ApplicationJob
  queue_as :mailers

  # Send notification for a review status change
  # @param review_id [Integer] The user review ID
  # @param event [String] The event type: 'approved', 'rejected', 'flagged'
  def perform(review_id, event)
    review = UserReview.find(review_id)

    case event
    when "approved"
      ReviewNotificationMailer.review_approved(review).deliver_now
    when "rejected"
      ReviewNotificationMailer.review_rejected(review).deliver_now
    when "flagged"
      ReviewNotificationMailer.review_flagged(review).deliver_now
    else
      Rails.logger.warn "Unknown review notification event: #{event}"
    end
  end
end
