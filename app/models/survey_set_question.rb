class SurveySetQuestion < ActiveRecord::Base
  
  belongs_to :survey_set
  belongs_to :question

  before_validation :assign_default_position

  scope :ordered_by_position, -> { order('position ASC') }
  
  protected
  
  def assign_default_position
    self.position ||= max_position_for_set + 1
  end
  
  def max_position_for_set
    ssq = survey_set.survey_set_questions.ordered_by_position.last
    ssq ? ssq.position : 0
  end
end
