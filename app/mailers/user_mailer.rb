# Mailer for sending user welcome and account-related emails
class UserMailer < ApplicationMailer
  # Send welcome email to new users after successful OAuth registration
  # @param user [User] The newly registered user
  def welcome_email(user)
    @user = user
    @login_url = root_url

    mail(
      to: user.email,
      subject: "Welcome to GamesReview.com!"
    )
  end

  # Notify user when their email is verified
  # @param user [User] The user whose email was verified
  def email_verified(user)
    @user = user
    @profile_url = root_url

    mail(
      to: user.email,
      subject: "Email Verified - Your GamesReview.com Account is Ready"
    )
  end
end
