class UserDecorator < Draper::Decorator
  include ActionView::Helpers
  delegate_all

  def first_name
    object.first_name || object.email
  end

  def scores_updated_day
    time_ago_in_words(object.personal_scores.order(published_at: :desc).first.published_at) + ' ago'
  end
end
