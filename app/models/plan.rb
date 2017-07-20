class Plan < ActiveRecord::Base
  is_impressionable
  has_many :subscriptions

  validates_presence_of :name
  validates_presence_of :interval
  validates_numericality_of :price, :numeric => true

  scope :stripe_plans, -> { where :stripe_plan => true }

  def free?
    price == 0.0 && stripe_plan == false
  end

  def subscription_quantity(subscription)
    if metered?
      subscription.subscription_users.billable_count
    else
      1
    end
  end

end


