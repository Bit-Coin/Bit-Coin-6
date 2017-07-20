class Job::UpdateScores
  extend Resque::Plugins::Heroku
  @queue = :scores

  # pass {force: true} to recalc everyone and their companies
  # {user_ids: [1,2,3,4]} for just those users and their companies
  # default is only users with complete (unscored) surveys and their companies

  def self.perform(options={})
    if options.count > 0
      Resque.logger.info "Entering Job::UpdateScores at #{Time.now} with options = #{options.to_s}"
    else
      Resque.logger.info "Entering Job::UpdateScores at #{Time.now}"
    end

    # Find users who need updating
    if options.fetch(:force, false)
      Resque.logger.info "FORCE = TRUE: Recalculating all users' scores regardless of new surveys"
      user_ids = Survey.scorable.current.pluck(:receiver_id).uniq
    elsif options[:user_ids] && options[:user_ids].any?
      user_ids = options[:user_ids]
    else
      user_ids = Survey.complete.current.pluck(:receiver_id).uniq
    end

    # Calculate Your Score and Self Score
    user_ids.each do |u_id|
      Resque.enqueue(Job::UpdatePersonalScores, u_id)
      Resque.enqueue(Job::UpdateSelfScores, u_id)
    end
    
    # Calculate Company Average
    company_ids = User.where('id in (?)', user_ids).pluck(:company_id).uniq
    company_ids.each do |c_id|
      Resque.enqueue(Job::UpdateCompanyScores, c_id)
    end
    
    # Report out
    message = "Job::UpdateScores completed at #{Time.now}"
    if Rails.env.production?
      HTTParty.get("https://nosnch.in/93f38ff2fb?m=#{CGI.escape(message)}")
    end
    Resque.logger.info message
    Rails.logger.info message
  end
end
