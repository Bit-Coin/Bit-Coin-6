class Response < ActiveRecord::Base
  belongs_to :survey
  belongs_to :question
  belongs_to :characteristic

  validate :survey_open?, on: :update
  validates_presence_of :question_id, :characteristic_id, :survey_id

  RANDOM_SCORE_SQL = %q{ trunc(random()*2 + random()*2 + 2) }

  def button_class
    self.score.blank? ? 'pending' : 'complete'
  end

  def randomize_score
    self.score = self.class.random_score
  end

  # Class
  
  def self.random_score
    (rand()*2 + rand()*2 + 2).to_i
  end

  private

  def survey_open?
    errors.add(:state, 'must be open in order to update') unless survey.open?
  end
end
