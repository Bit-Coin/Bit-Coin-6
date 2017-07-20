class SurveySet < ActiveRecord::Base
  
  # TODO handle surveyables & custom survey sets

  belongs_to :survey_series
  belongs_to :surveyable, polymorphic: true
  has_many :survey_set_questions, -> { order "position" }
  has_many :questions, :through => :survey_set_questions
  has_many :surveys
  
  scope :active, -> { where(:state => 'active') }
  scope :ordered_by_position, -> { order('position ASC')}
  scope :for_type, -> (surveyable_type) { where('surveyable_type = ?', surveyable_type) }
  scope :for_others, -> { where(:self_survey => false) }
  scope :for_self, -> { where(:self_survey => true) }
  
  before_validation :assign_default_state, only: [:create]
  before_validation :assign_default_position, only: [:create]

  validates_presence_of :name, :position, :survey_series_id
  validate :unique_position
  
  class << self
    def max_position
      ss = self.ordered_by_position.last
      ss ? ss.position : 0
    end
  end
    
  def assign_default_state
    self.state ||= 'active'
  end
  
  def assign_default_position
    return if self.position.present?
    if self.survey_series.survey_sets.where('id is not null').any?
      self.position = survey_series.survey_sets.order(position: :desc).first.position + 1
    else
      self.position = 1
    end
  end

  private

  def unique_position
    if (self.persisted? && self.survey_series.survey_sets.where('id != ?', self.id)
        .pluck(:position).include?(self.position)) ||
        (!self.persisted? && self.survey_series.survey_sets.pluck(:position)
            .include?(self.position))
      errors.add(:position, 'is not unique for this survey series')
    end
  end
end
