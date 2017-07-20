module Scopes::Surveys

  def next_survey
    if surveys.open.for_others.any?
      surveys.open.for_others.newest
    elsif surveys.open.any? # self-survey
      surveys.open.newest
    else
      nil
    end
  end

  def survey_after_next
    surveys.open.order(created_at: :desc).second
  end

  def open_surveys
    surveys.open
  end
  
  def open_surveys_excluding(survey)
    surveys.reload.open.for_others.where('id <> ?', survey.id).order(created_at: :desc)
  end

  def scoped_responses
    Response.where('responses.survey_id in (?)', surveys.pluck(:id))
  end

end
