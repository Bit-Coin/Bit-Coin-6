class Characteristic < ActiveRecord::Base
  belongs_to :parent_characteristic, class_name: 'Characteristic'
  has_many :questions
  has_many :scores
  has_many :responses
  has_many :components, class_name: 'Characteristic',
    foreign_key: 'parent_characteristic_id'
  has_many :surveys

  accepts_nested_attributes_for :components

  validate :nil_survey_name_for_components
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of [:score_name, :survey_name], if: Proc.new { |c| c.parent_characteristic_id.blank? }

  scope :ripple_effect_score, -> { find(1) } # set in seeds
  scope :top_level, -> { where('parent_characteristic_id is null') }
  scope :res_characteristics, -> { where('id < 7') } # legacy support

  def self_with_components
    raise 'Only for top level characteristics' unless self.parent_characteristic_id.blank?
    self.class.where('parent_characteristic_id = ? or id = ?', self.id, self.id).order(:id)
  end

  def all_questions
    questions.any? ? questions : Question.where('characteristic_id in (?)', components.pluck(:id))
  end

  private

  def nil_survey_name_for_components
    if parent_characteristic_id && survey_name 
      errors.add :survey_name, "must be nil for component characteristics"
    end
  end
end
