class Job::OneTime::MigrateEvent
  @queue = :migrate 

  def self.perform(event_id)
    e = Event.find(event_id)
    if e.eventable.messageable_type == 'User'
      e.company = e.eventable.messageable.try(:company)
      e.user = e.eventable.messageable
    elsif e.eventable.messageable_type == 'Survey'
      e.company = e.eventable.messageable.try(:giver).try(:company)
      e.user = e.eventable.messageable.try(:giver)
    end
    e.body = e.delete_detail
    e.type = 'MessageEvent'
    e.name = e.delete_type_old
    e.body['sg_event_id'] = e.delete_sg_event_id
    e.save!
  end
end
