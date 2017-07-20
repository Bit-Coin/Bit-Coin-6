class BaseMailer < ActionMailer::Base
  include Resque::Mailer
  extend Resque::Plugins::Heroku
  add_template_helper ApplicationHelper

  default from: 'no-reply@ripplecrew.com'
  domain = ActionMailer::Base.smtp_settings[:domain]
  default "Message-ID" => Proc.new { "<#{SecureRandom.uuid}@ripplecrew.com>" }

  after_action :log_message

  private

  def log_message
    # Record the message
    Message.create(
      uuid: message.message_id, 
      original: message.to_json,
      sender: self.class.to_s + '#' + self.instance_variable_get('@_action_name'),
      messageable: get_messageable
    )
  end

  def get_messageable
    # could be survey or user
    messageable = nil
    %w(@user @survey).each do |r|
      messageable = self.instance_variable_get(r)
      break if messageable
    end
    messageable
  end
end
