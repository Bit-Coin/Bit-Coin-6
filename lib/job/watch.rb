class Job::Watch
  extend Resque::Plugins::Heroku

  @queue = :watch

  class << self
    def perform
      failed_resque_jobs
      company_survey_series
    end

    def failed_resque_jobs
      size = Resque.info[:failed]
      if size > 0
        Ripple::ActivityLogger.new(channel: '#alert', text: "#{size} failed Resque jobs").log!
      end
      size
    end

    def company_survey_series
      fishy = []
      Company.all.each do |c|
        fishy << c.id unless c.company_survey_series.any?
      end
      if fishy.any?
        Ripple::ActivityLogger.new(channel: '#alert', text: "Companies #{fishy} have no SurveySeries").log!
      end
      fishy
    end
  end
end
