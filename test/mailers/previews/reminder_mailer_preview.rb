class ReminderMailerPreview < ActionMailer::Preview
  def reminder
    ReminderMailer.reminder(User.rippler.first)
  end

  def declared_dead
    ReminderMailer.declared_dead(Survey.open.first.giver.id)
  end
end
