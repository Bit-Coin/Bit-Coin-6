class Subscription < ActiveRecord::Base
  
  include TimeSpannable
  include Eventable
  
  belongs_to :company
  belongs_to :plan
  belongs_to :owner, :class_name => 'User'
  
  has_many :subscription_users do
    def billable_count
      self.active_time.count
    end
  end
  
  has_many :users, :through => :subscription_users
  
  validates_presence_of :state
  validates_presence_of :plan
  
  PENDING = 'pending'
  ACTIVE = 'active'
  UNPAID = 'unpaid'
  CANCELED = 'canceled'
  STATES = [PENDING, ACTIVE, UNPAID, CANCELED]
  FOREVER = DateTime.parse('3000-01-01') # indefinitely in the future
  
  scope :pending_state,  -> { where(:state => PENDING)  }
  scope :active_state,   -> { where(:state => ACTIVE)   }
  scope :unpaid_state,   -> { where(:state => UNPAID)   }
  scope :canceled_state, -> { where(:state => CANCELED) }
  scope :pending_time,   -> { where("start_at > ?", DateTime.now) }
  scope :active_time,    -> { where("start_at < ? and end_at > ?", DateTime.now, DateTime.now) }
  scope :lapsed_time,    -> { where("end_at < ?", DateTime.now) }
  
  def active? 
    state === ACTIVE 
  end
  
  def free?
    plan.free?
  end
  
  def has_stripe_record?
    stripe_customer_id && stripe_subscription_id
  end
  
  def has_end?
    end_at && end_at < Subscription::FOREVER
  end
  
  def update_state_for_invoice_hook(invoice_hook, invoice)
    if invoice_hook === 'payment_succeeded'
      update_attributes(:state => ACTIVE)
    elsif invoice_hook === 'payment_failed'
      update_attributes(:state => UNPAID)
    end
  end
  
  def record_event_for_invoice_hook(invoice_hook, invoice_data)
    total = invoice_data['total'].to_i / 100
    i_id = invoice_data['id']
    if invoice_hook === 'payment_succeeded'
      subscription_events.create({
        :name => SubscriptionEvent::PAYMENT,
        :body => {
          :invoice_hook => 'payment_succeeded',
          :description => "Payment of $#{total} successful for invoice #{i_id}"
        }
      })
    elsif invoice_hook === 'payment_failed'
      subscription_events.create({
        :name => SubscriptionEvent::PAYMENT,
        :body => {
          :invoice_hook => 'payment_failed',
          :description => "Payment of $#{total} failed for invoice #{i_id}"
        }
      })
    elsif invoice_hook === 'created'
      subscription_events.create({
        :name => SubscriptionEvent::CREATED,
        :body => {
          :invoice_hook => 'created',
          :description => "Invoice for $#{total} created as #{i_id}"
        }
      })
    elsif invoice_hook === 'updated'
      subscription_events.create({
        :name => SubscriptionEvent::UPDATED,
        :body => {
          :invoice_hook => 'updated',
          :description => "Invoice for $#{total} id #{i_id} updated"
        }
      })
    end
  end
end

