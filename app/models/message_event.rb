class MessageEvent < Event

  scope :death, -> { where('eventable_type = ? and name in (?)', 'Message', %w(bounce dropped unsubscribe)) }

  EVENTS = {
    deferred: {},
    processed: {},
    delivered: {},
    open: {},
    click: {},
    dropped: {severity: Event::WARN},
    bounce: {severity: Event::WARN},
    unsubscribe: {severity: Event::WARN},
    spamreport: {severity: Event::WARN}
  }

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

  # Event-type-specific post-processing
  # https://sendgrid.com/docs/API_Reference/Webhooks/event.html
  def deferred; end
  def processed; end
  def delivered; end
  def open; end
  def click; end

  def dropped
    eventable.messageable.recipient.bounce!
  end

  def bounce
    eventable.messageable.recipient.bounce!
  end

  def unsubscribe
    eventable.messageable.recipient.unsubscribe!
  end

  def spamreport
    eventable.messageable.recipient.unsubscribe!
  end

  private

  def set_user_and_company
    if eventable.messageable # could be nil
      self.user = eventable.messageable.recipient
      self.company = eventable.messageable.recipient.company
    end
  end
end
