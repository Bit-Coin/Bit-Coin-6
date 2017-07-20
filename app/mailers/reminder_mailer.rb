class ReminderMailer < BaseMailer
  layout 'email'

  # Normal reminder
  def reminder(user_id)
    @user = User.find(user_id)
    mail(to: @user.email, subject: "[Ripple] You have open surveys to complete")
  end

  # If you've never responded to anything after one month and
  # four reminders, you're considered dead
  def declared_dead(user_id)
    @user = User.find(user_id)
    mail(to: @user.email, subject: '[Ripple] Looks like you\'re not there')
  end
end
