class Job::CreateCompanySurveys
  extend Resque::Plugins::Heroku
  @queue = :surveys

  def self.perform(company_ids, options={})
    company_ids.each do |company_id|
      company = Company.find(company_id)
      company.survey_plans.due.each do |sp|
        #survey will create only when receiver and giver present
        sp.create_next_survey if sp.receiver.present? && sp.giver.present?
      end
    end
  end
end
