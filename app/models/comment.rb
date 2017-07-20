class Comment < ActiveRecord::Base
  belongs_to :receiver, class_name: 'User'
  belongs_to :response
  belongs_to :question
  belongs_to :survey

  before_save :truncate_text
  before_validation :set_question

  validates_presence_of :receiver, :survey

  STATES = %w(draft final)
  scope :draft, -> { where('state = ?', 'draft') }
  scope :final, -> { where('state = ?', 'final') }
  scope :general, -> { where('response_id is null') }

  def finalize!
    update_attributes(state: 'final')
  end

  private

  def truncate_text
    self.text = text[0..255]
  end

  # Denormalize question_id for performance
  # REMEMBER:  General comments have nil responses!
  def set_question
    self.question_id = response.question_id if response && question_id.blank?
  end
end
