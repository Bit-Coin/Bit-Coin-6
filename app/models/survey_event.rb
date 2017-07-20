class SurveyEvent < Event

  EVENTS = {
    completed: {severity: Event::NOTIFY}
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
    self.user = eventable.giver
    self.company = eventable.receiver.company
  end
end
