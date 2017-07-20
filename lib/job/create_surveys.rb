class Job::CreateSurveys
  extend Resque::Plugins::Heroku
  @queue = :surveys

  def self.perform(company_ids=[], options={})
    Resque.logger.info "Starting Job::CreateSurveys at #{Time.now}"

    # Break them up by company so the work can be split across
    # workers.
    company_ids = company_ids.any? ? company_ids : Company.all.collect(&:id)
    Resque.enqueue(Job::CreateCompanySurveys, company_ids)

    message = "Survey creation jobs enqueued"
    # Check in with Dead Man's Snitch
    if Rails.env.production?
      HTTParty.get("https://nosnch.in/c4f9856299?m=#{CGI.escape(message)}")
    end
    Resque.logger.info message
    message
  end
end
