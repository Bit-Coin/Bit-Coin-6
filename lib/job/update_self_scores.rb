class Job::UpdateSelfScores
  extend Resque::Plugins::Heroku
  @queue = :scores
  
  def self.perform(user_id, options={})
    user = User.find(user_id)

    scorable_current_self_surveys = user.self_feedback.scorable.current
    
    if scorable_current_self_surveys.any?     
      survey_scorer = Ripple::SelfSurveyScorer.new(user, scorable_current_self_surveys)
      survey_scorer.create_scores
      survey_scorer.mark_scored
      Resque.logger.info("Updated self scores for #{user.email}")
      true
    else
      Resque.logger.debug("No self scores to update for #{user.email}")
      false
    end
  end
end
