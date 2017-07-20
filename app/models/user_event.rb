class UserEvent < Event
  include Eventable
  EVENTS = {
    sign_in: {severity: Event::NOTIFY, icon_emoji: ':tada:'},
    admin_proxy: {severity: Event::NOTIFY, icon_emoji: ':tada:'},
    failed_reset: {severity: Event::NOTIFY, icon_emoji: ':lemon:'},
    password_reset: {severity: Event::INFO},
    bad_password: {severity: Event::NOTIFY, icon_emoji: ':squirrel:'}
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
    self.user = self.eventable
    self.company = self.eventable.company
  end

end
