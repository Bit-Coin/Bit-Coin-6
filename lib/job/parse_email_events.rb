class Job::ParseEmailEvents
  extend Resque::Plugins::Heroku
  @queue = :mailer

  def self.perform(events)
    events.each do |e|
      message = Message.find_by_sg_message_id(e['sg_message_id']) if e['sg_message_id'].present?
      message = Message.find_by_uuid(e['smtp-id']) if message.blank? && e['smtp-id'].present?
      unless message
        user = User.find_by_email(e['email']) # could be nil
        message = Message.create!({
          messageable: user, 
          uuid: e['smtp-id'],
          sg_message_id: e['sg_message_id']
        })
      end
      message_user = message.messageable.recipient if message.messageable
      message_company = message_user.present? ? message_user.company : nil
      event = message.message_events.create!({
        name: e['event'], 
        type: 'MessageEvent',
        severity: 'info',
        user: message_user,
        company: message_company,
        body: e
      })
      event.send(e['event']) if message.messageable # event-specific actions
    end
  end

  # post-processing handled by Event methods
end
