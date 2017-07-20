class Question < ActiveRecord::Base
  belongs_to :characteristic
  belongs_to :response_set
  has_many :responses
  has_many :comments

  validates_presence_of :response_set_id, :characteristic_id

  attr_reader :survey_set
  attr_accessor :parent_characteristic_id

  # TODO disallow editing question text if there are responses
  # TODO support deactivating a question

  def text
    other_phrased
  end

  def parent_characteristic
    if characteristic && characteristic.parent_characteristic.present?
      characteristic.parent_characteristic
    elsif characteristic.blank? && parent_characteristic_id
      Characteristic.find(parent_characteristic_id)
    else
      characteristic
    end
  end

  def personalized_text_for(user)
    other_phrased.gsub('#{receiver.first_name}', user.decorate.first_name)
  end

  def comments_for(user)
    comments.where('receiver_id = ?', user.id)
  end

  def characteristics_for_select
    if characteristic.present? && characteristic.parent_characteristic.present?
      char = parent_characteristic
    elsif characteristic.present?
      char = characteristic
    else # new record
      char = Characteristic.find(parent_characteristic_id)
    end
    char.components.map { |c| [c.name, c.id] }
  end

  def response_sets_for_select
    ResponseSet.all.map { |r| [r.description, r.id] }
  end
end
