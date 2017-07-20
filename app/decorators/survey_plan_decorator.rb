class SurveyPlanDecorator < Draper::Decorator
  include ActionView::Helpers
  delegate_all

  def truncated_giver_email
    if giver.first_name
      "#{giver.full_name} <#{truncate(object.giver.email, length: 20)}>"
    else
      truncate(object.giver.email, length: 50)
    end
  end

  def state_details
    {
      'created'   => "Invitation will be sent momentarily. <a href='javascript:location.reload()'>Refresh</a> to confirm.",
      'notified'  => "Invited #{notified_on_in_words} ago. #{message_status}",
      'active'    => "Next survey due in #{distance_of_time_in_words(Time.now, object.next_due)}.",
      'bounced'   => "Bouncing. Bad email?",
      'unsubscribed' => "Not currently participating.",
      'declined'  => "Declined to respond.",
      'timed_out' => "No response after #{object.giver.company.settings[:weeks_until_invitations_expire]} weeks.",
      'deleted'   => "Deleted."
    }[object.state]
  end

  # danger d9534f
  # warn f0ad4e
  # success 5cb85c
  
  def state_icon
    danger = "#d9534f"
    warning = "#f0ad4e"
    success = "#5cb85c"
    primary = "#337ab7"
    default = "#666666"
    
    case object.state
    when 'created'
      icon = 'fa fa-envelope'
      color = primary
    when 'active'
      icon = 'fa fa-user'
      color = success
    when 'notified'
      icon = 'fa fa-user'
      color = warning
    when 'bounced'
      icon = 'fa fa-question'
      color = danger
    when 'unsubcribed'
      icon = 'fa fa-user'
      color = danger
    when 'declined'
      icon = 'fa fa-user'
      color = danger
    when 'timed_out'
      icon = 'fa fa-question'
      color = danger
    when 'unsubscribed'
      icon = 'fa fa-user'
      color = danger
    when 'deleted'
      icon = 'fa fa-user'
      color = danger
    else
      icon = 'fa fa-question'
    end
    %Q{ <i class="#{icon}" style="color: #{color}"></i> }
  end

  def active_since_in_words
    return '--' unless object.active_since
    distance_of_time_in_words(Time.now, object.active_since)
  end

  def notified_on_in_words
    distance_of_time_in_words(Time.now, object.last_reminded_at || object.created_at)
  end

  def message_status
    survey = object.surveys.first
    return 'Error. Please notify support@ripplecrew.com.' unless survey
    last_message = survey.messages.last
    if last_message && last_message.message_events.last
      'Message ' + last_message.message_events.last.type + 'ed.' # click => clicked, open => opened
    else
      'Message delivered.'
    end
  end

  def expires_in_days
    if object.state == 'notified'
      distance_of_time_in_words_to_now(object.last_reminded_at + 
        object.giver.company.settings[:weeks_until_invitations_expire].weeks)
    else
      'never'
    end
  end
  
  def relationship_type_label
    if object.relationship_type.present?
      object.relationship_type.capitalize
    elsif user_role.role.try(:name)
      user_role.role.name.capitalize
    else
      'Colleague'
    end
  end
end
