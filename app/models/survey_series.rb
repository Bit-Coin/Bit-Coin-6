class SurveySeries < ActiveRecord::Base
  belongs_to :parent_characteristic, class_name: 'Characteristic'
  has_many :company_survey_series
  has_many :survey_sets
  has_many :companies, through: :company_survey_series

  validates_presence_of :parent_characteristic_id, :default_config
  validates :name, presence: true, uniqueness: true
  
  def self.for_self
    where('default_config @> ?', {for_self: true}.to_json)
  end

  def self.for_others
    where('default_config @> ?', {for_self: false}.to_json)
  end
end
