class Job::UpdateCompanyScores
  extend Resque::Plugins::Heroku
  @queue = :scores

  N_MIN = Rails.env.production? ? Ripple::Globals::MIN_SURVEYS_FOR_SCORES : 1 # minimum sample
  
  def self.perform(company_id, options={})    
    company = Company.find(company_id)
    feedback = company.feedback.for_others

    if feedback.count >= N_MIN

      ActiveRecord::Base.transaction do
        company.scores_for_company.published.update_all(:state => 'past')
        feedback.score_current_feedback!
      end
    end
    
    Resque.logger.info("Updated company scores for #{company.name}")
  end
end
