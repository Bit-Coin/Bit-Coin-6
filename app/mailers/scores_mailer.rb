class ScoresMailer < BaseMailer
  layout 'email'
  def your_scores_are_ready(user_id)
    @user = User.find(user_id)
    subject = "[Ripple] Your Ripple Effect Score is ready"
    mail(to: @user.email, subject: subject)
  end
end
