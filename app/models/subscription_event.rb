class SubscriptionEvent < Event

  CUSTOMER_CREATED = 'customer_created'
  CREATED = 'created'
  CANCELED = 'canceled'
  UPGRADED = 'upgraded'
  PAYMENT = 'payment'
  UPDATED = 'updated'

  EVENTS = HashWithIndifferentAccess.new({
    CUSTOMER_CREATED => {severity: Event::NOTIFY},
    CREATED => {
      severity: Event::NOTIFY,
      body: { description: "Created subscription for new customer" }
    },
    CANCELED => {severity: Event::NOTIFY},
    UPGRADED => {severity: Event::NOTIFY},
    PAYMENT => {severity: Event::NOTIFY},
    UPDATED => {severity: Event::NOTIFY}
  })

  scope :ordered, -> { order(:id) }

  rails_admin do
    include_fields :id, :eventable_id, :eventable_type, :note
    list do
      field :id
      field :created_at
      field :updated_at
      field :eventable_id
      field :eventable_type
    end
  end

  private

  def set_user_and_company
    self.user = eventable.owner
    self.company = eventable.company
  end
end
