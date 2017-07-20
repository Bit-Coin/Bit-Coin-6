class Job::Remind
  extend Resque::Plugins::Heroku
  @queue = :surveys

  def self.perform(options={})

    list = User.need_reminding
    
    if list.any?
      deads, reminds = Ripple::Reminder.new(list).remind!
      message = "#{reminds} Users were reminded and #{deads} marked unresponsive"
      Ripple::ActivityLogger.new(channel: '#activity', text: message).log!
    else
      message = "No one to remind right now"
    end

    if Rails.env.production?
      HTTParty.get("https://nosnch.in/9b18d9a926?m=#{CGI.escape(message)}")
    end
    Resque.logger.info message
    message
  end
end
