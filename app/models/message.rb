class Message < ActiveRecord::Base

  belongs_to :messageable, polymorphic: true
  has_many :events, as: :eventable

  include Eventable
  rails_admin do
    list do
      field :id
      field :created_at
      field :updated_at
      field :messageable_id
      field :messageable_type
    end
  end
  def recipient
    if messageable
      messageable.recipient.email
    else
      'unknown'
    end
  end

  def self.dead
    event_ids = MessageEvent.death.pluck(:eventable_id)
    where('id in (?)', event_ids)
  end
end
