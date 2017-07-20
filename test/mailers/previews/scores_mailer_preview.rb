class ScoresMailerPreview < ActionMailer::Preview
  def your_scores_are_ready
    ScoresMailer.your_scores_are_ready(User.first.id)
  end
end
