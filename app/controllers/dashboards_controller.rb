class DashboardsController < ApplicationController

  layout 'bare'

  def show
    @competency_models = current_user.company.parent_characteristics
    @all_cm_scores = {}
    @published_at = nil
    @competency_models.each do |cm|
      @score_reporter = Ripple::CharacteristicScoreReporter.new(current_user, cm)
      if @score_reporter.fetch_all_scores
        cm_scores = {
          :cm_id => cm.id,
          :published_at => @score_reporter.published_at,
          :total_responses => @score_reporter.total_responses,
          :personal => @score_reporter.personal_scores,
          :company => @score_reporter.company_scores,
          :self => @score_reporter.self_scores
        }
        @all_cm_scores[cm.score_name] = cm_scores
      else
        @all_cm_scores[cm.score_name] = false
      end
    end
    @open_surveys = current_user.surveys.for_others.open.order(created_at: :asc).includes(:receiver).decorate
  end

  def questions
    pcid = params[:cm_id]
    user = params[:user_id].present? ? User.find_by_id(params[:user_id]) : current_user
    @score_reporter = Ripple::QuestionScoreReporter.new(user, pcid)
    @has_scores = @score_reporter.fetch_all_scores
    if @has_scores
      @res = {
        :personal => @score_reporter.personal_scores,
        :company => @score_reporter.company_scores,
        :self => @score_reporter.self_scores
      }
      @general_comments = user.comments.general
    else
      @res = false
    end
  end


  def history
    pcid = params[:cm_id]
    user = params[:user_id].present? ? User.find_by_id(params[:user_id]) : current_user
    # @days_range = params[:days].present? ? params[:days].to_i : 30
    time_range = Time.now-1.year..Time.now
    @competency_models = Characteristic.find_by_id(pcid).self_with_components
    @scores = @competency_models.map{|cm| {name: cm.name.titleize, data: user.personal_scores.characteristic_scores.where(:characteristic_id => cm.id, :published_at => time_range).order(:published_at).all.map{|s| s.mean.to_f.round(2)}}}
    @dates = user.personal_scores.characteristic_scores.where(:characteristic_id => pcid, :published_at => time_range).order(:published_at).map{|s| s.published_at.strftime("%d-%b-%Y")}
  end

end
