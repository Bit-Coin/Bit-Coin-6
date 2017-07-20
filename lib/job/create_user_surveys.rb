class Job::CreateUserSurveys
  extend Resque::Plugins::Heroku
  @queue = :surveys

  def self.perform(user_id, options={})
    user = User.find(user_id)
    if user.rippler? && user.active? && user.can_create_survey?
      user.giver_survey_plans.due.each { |sp| sp.create_next_survey }
    end
  end
end
