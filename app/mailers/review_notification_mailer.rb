# Mailer for sending review-related notifications to users
class ReviewNotificationMailer < ApplicationMailer
  # Notify user when their review is approved
  # @param review [UserReview] The approved review
  def review_approved(review)
    @review = review
    @user = review.user
    @game = review.game
    @review_url = root_url # Will link to game page once routes exist

    mail(
      to: @user.email,
      subject: "Your review of #{@game.title} has been approved!"
    )
  end

  # Notify user when their review is rejected
  # @param review [UserReview] The rejected review
  def review_rejected(review)
    @review = review
    @user = review.user
    @game = review.game
    @guidelines_url = root_url # Will link to guidelines page once routes exist

    mail(
      to: @user.email,
      subject: "Review Status Update for #{@game.title}"
    )
  end

  # Notify user when their review is flagged for moderation
  # @param review [UserReview] The flagged review
  def review_flagged(review)
    @review = review
    @user = review.user
    @game = review.game
    @guidelines_url = root_url # Will link to guidelines page once routes exist

    mail(
      to: @user.email,
      subject: "Your review of #{@game.title} requires attention"
    )
  end
end
