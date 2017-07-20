class SurveyDecorator < Draper::Decorator
  include ActionView::Helpers
  delegate_all

  def due_in
    if object.past_due?
      'Past Due'
    else
      distance_of_time_in_words(object.due_date, Time.now)
    end
  end

  def due_in_phrase
    if object.past_due?
      'Past Due'
    else
      "Due in #{due_in}"
    end
  end

  def past_due_td_class
    if object.past_due?
      'past-due'
    else
      ''
    end
  end

  def self_survey_link_text
    "Complete a #{object.parent_characteristic.survey_name} about yourself"
  end

  def others_survey_link_text
    object.receiver.full_name + " (#{object.parent_characteristic.survey_name})"
  end
end
