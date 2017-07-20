class Ripple::Reminder

  def initialize(users)
    @users = users
  end

  def remind!
    deads = reminds = 0
    @users.each do |u|
      next if u.do_not_contact?
      if u.appears_unresponsive?
        u.mark_unresponsive!
        ReminderMailer.declared_dead(u.id).deliver
        deads += 1
      else
        u.cull_expired_invitations!
        if u.surveys.open.any? # all invitations could have been culled
          ReminderMailer.reminder(u.id).deliver
          reminds += 1
        end
      end

      # Mark the user as reminded, so they don't get reminded
      # again right away.  TODO: this should really be triggered
      # by a SendGrid postback 'delivered'.
      u.update_attributes(last_reminded_at: Time.now)


      # Do not update invitation.reminded_at here.  That only happens
      # when a user or admin resends it.  invitations.reminded_at
      # is used mostly for display ('sent 4 hours ago') type things.
    end
    return [deads, reminds]
  end
end
