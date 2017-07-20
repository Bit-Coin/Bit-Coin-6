class SystemEvent < Event
  include Eventable

  EVENTS = {
    bad_email: {severity: Event::CRITICAL, icon_emoji: ':question:'}
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

  private

  def set_user_and_company
    self.user = self.company = nil # system events don't have them
  end
end
