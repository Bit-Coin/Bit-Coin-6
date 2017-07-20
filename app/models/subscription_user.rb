class SubscriptionUser < ActiveRecord::Base
  
  include TimeSpannable
  
  belongs_to :subscription
  belongs_to :user
  
  validates_presence_of :subscription_id
  validates_presence_of :user_id
  
  scope :pending_time, -> { where("start_at > ?", DateTime.now) }
  scope :active_time,  -> { where("start_at < ? and end_at > ?", DateTime.now, DateTime.now) }
  scope :lapsed_time,  -> { where("end_at < ?", DateTime.now) }
  
end

