class Job::UpdatePersonalScores
  extend Resque::Plugins::Heroku
  @queue = :scores

  N_MIN = Rails.env.production? ? Ripple::Globals::MIN_SURVEYS_FOR_SCORES : 1 # minimum sample
  
  def self.perform(user_id, options={})
    
    demo_company = Company.where('name = ?', Ripple::Globals::TESTDRIVE_COMPANY_NAME).first
    force = options.fetch(:force, false)
    user = User.find(user_id)

    individual_feedback = user.others_feedback
    
    if  individual_feedback.count >= N_MIN || 
        (force && (individual_feedback.count > 0))

      ActiveRecord::Base.transaction do
        user.personal_scores.published.update_all(:state => 'past')
        individual_feedback.score_current_feedback!
      
        if (user.personal_scores.published.count == 0) && (user.company != demo_company)
          ScoresMailer.your_scores_are_ready(user.id).deliver
          message = "#{user.email} is getting a Ripple Effect Score for the first time!"
          logger = Ripple::ActivityLogger.new(:text => message, :icon_emoji => ':chart_with_upwards_trend:')
          logger.log!
        end
      end
    end
    
    Resque.logger.info("Updated personal scores for #{user.email}")
  end
  
end
