class Job::AnswerBot
  extend Resque::Plugins::Heroku
  @queue = :surveys

  # Pass in a list of survey ids to auto-answer those surveys
  # Pass in a list of user ids to auto-answer all open surveys for those users

  def self.perform(options={})
    num_answered = 0

    surveys = options[:surveys] || []
    users = options[:users] || []

    Survey.where('id in (?)', surveys).each do |s|
      if s.open?
        ActiveRecord::Base.transaction do
          Response.where('survey_id = ?', s.id).update_all('score = trunc(random()*2 + random()*2 + 2)')
        end
        s.update_attributes({ state: :complete, completed_at: Time.now })
        num_answered = num_answered + 1
      end
    end

    User.where('id in (?)', users).each do |u|
      num_foru = 0
      u.surveys.for_others.open.each do |s|
        ActiveRecord::Base.transaction do
          Response.where('survey_id = ?', s.id).update_all('score = trunc(random()*2 + random()*2 + 2)')
        end
        s.update_attributes({ state: :complete, completed_at: Time.now })
        num_foru = num_foru + 1
        num_answered = num_answered + 1
      end

      if num_foru > 0
        message = "AnswerBot answered #{num_foru} surveys for #{u.full_name}"
        Resque.logger.info message
        Ripple::ActivityLogger.new(channel: '#activity', text: message, 
          username: 'AnswerBot', icon_emoji: ':game_die:').log!
      end
    end
    
    if num_answered > 0      
      message = "A total of #{num_answered} surveys were filled out by the AnswerBot"
    else
      message = "AnswerBot did not find any open surveys to answer"
    end

    Resque.logger.info message
    Ripple::ActivityLogger.new(channel: '#activity', text: message, 
      username: 'AnswerBot', icon_emoji: ':game_die:').log!

    message
  end
end