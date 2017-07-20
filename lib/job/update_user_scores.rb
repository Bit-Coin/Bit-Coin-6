class Job::UpdateUserScores
  extend Resque::Plugins::Heroku
  @queue = :scores

  N_MIN = Rails.env.production? ? Ripple::Globals::MIN_SURVEYS_FOR_SCORES : 1 # minimum sample

  def self.perform(options={})

    raise 'Deprecated.  Use Job::UpdatePersonalScores instead.'

    # Option { :recalc => 'true' } means recalculate scores for all users
    # Option { :force => 'true' } means ignore the minimum survey requirement
    # Option { :users => [] } is a list of specific user IDs to operate on

    # Precedence: if :recalc == true then the job iterates over every user, in
    #   which case the value of :users (if any) is ignored
    # :force can be set true with or without :recalc (they are additive)

    recalc = options.fetch(:recalc, false)
    force = options.fetch(:force, false)
    user_ids = options[:users] || []

    demo_company = Company.find_by_name(Ripple::Globals::TESTDRIVE_COMPANY_NAME)

    if recalc
      Resque.logger.info "Recalculating all users' scores"
      user_ids = Survey.select(:receiver_id).distinct.scorable.current.pluck(:receiver_id)
    elsif user_ids.count == 0
      user_ids = Survey.select(:receiver_id).distinct.complete.current.pluck(:receiver_id)
    end

    Resque.logger.info "User IDs to score: #{user_ids.to_s}" if user_ids.count > 0

    User.where('id in (?)', user_ids).each do |user|
      cnt_new = user.others_feedback.complete.current.count
      cnt_scorable = user.others_feedback.scorable.current.count
      
      Resque.logger.info "#{user.email} has #{cnt_new} new surveys to score (#{cnt_scorable} total scorable)"

      individual_feedback = user.others_feedback

      if  individual_feedback.count >= N_MIN || 
          (force && (individual_feedback.count > 0))
          
        if (user.personal_scores.published.count == 0) && (user.company != demo_company)
          ScoresMailer.your_scores_are_ready(user.id).deliver
          message = "#{user.email} is getting a Ripple Effect Score for the first time!"
          Ripple::ActivityLogger.new(:text => message, :icon_emoji => ':chart_with_upwards_trend:').log!
        end
        user.personal_scores.published.update_all(:state => 'past')
        individual_feedback.score_current_feedback! 
      end
    end

    message = "Job::UpdateUserScores completed at #{Time.now}"

    # Check in with Dead Man's Snitch
    if Rails.env.production?
      HTTParty.get("https://nosnch.in/93f38ff2fb?m=#{CGI.escape(message)}")
    end

    Resque.logger.info message
    Rails.logger.info message

    message
  end
end