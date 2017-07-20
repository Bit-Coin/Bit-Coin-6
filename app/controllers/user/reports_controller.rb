class User::ReportsController < ApplicationController
  def index
    if params[:user_id].present?
     @user = User.find_by_id(params[:user_id])
    else
     @user = current_user
    end
    @competency_models = @user.company.parent_characteristics
    @all_cm_scores = {}
    @published_at = nil
    @competency_models.each do |cm|
      @score_reporter = Ripple::CharacteristicScoreReporter.new(@user, cm)
      @que_score_reporter = Ripple::QuestionScoreReporter.new(@user, cm.id)
      @has_scores = @que_score_reporter.fetch_all_scores 
      @questions = @que_score_reporter.questions.sort_by{|question| @que_score_reporter.personal_score_for_question(question)[:scores][:overall]}
      @highest_score_question = @questions.last
      @lowest_score_question = @questions.first

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
    @open_surveys = @user.surveys.for_others.open.order(created_at: :asc).includes(:receiver).decorate
  end

  def team_reports
    scope = current_user.manage_teams.order('id asc')
    if params[:team_id].present?
      @team_id = params[:team_id].to_i
      scope = scope.where(:id => @team_id)
    end
    @teams = scope

    @leaderboard = Array.new()
    @scores = Array.new()
    
    i = 0
    j = 0

    member_ids = @teams.collect(&:members).flatten.map(&:id).uniq
    members = User.where(:id => member_ids).rippler.active

    # @teams.each do |t|
      members.each do |m|
        # Leaderboard
        ic = SurveyPlan.for_others.where("giver_id = ? and state = 'active'", m.id).count
        os = Survey.for_others.open.where("giver_id = ?", m.id).count
        sf = Survey.for_self.scorable.where("giver_id = ?", m.id).count
        sc = Survey.for_others.scorable.where("giver_id = ?", m.id).count
        la = Survey.for_others.scorable.select("id, giver_id, date(completed_at)"). \
          where("giver_id = ?", m.id). \
          group("giver_id, date(completed_at)"). \
          order("date(completed_at) DESC"). \
          count("id").first
        lr = "#{m.last_reminded_at}"
        
        score = 0
        tot_surveys = 0
        b20_surveys = 0
        b10_surveys = 0

        cm = m.company.parent_characteristics.first
        @all_cm_scores = {}
        @score_reporter = Ripple::CharacteristicScoreReporter.new(m, cm)
        if @score_reporter.fetch_all_scores
          ripple_effect_score = @score_reporter.personal_scores.first[:scores][:overall]
        else
          ripple_effect_score = 0
        end


        @leaderboard[i] = 
         {
          :leader_score => '',
          :user_id => '',
          :user_name => '',
          :sp_count => '',
          :os_count => '',
          :sf_count => '',
          :sc_count => '',
          :last_activity => '',
          :last_reminded => ''
        }

        @leaderboard[i][:ripple_effect_score] = sprintf("%5.1f", ripple_effect_score)
        @leaderboard[i][:user_id] = "#{m.id}" 
        @leaderboard[i][:user_name] = "#{m.full_name}"
        @leaderboard[i][:sp_count] = "#{ic}"
        @leaderboard[i][:os_count] = "#{os}"
        @leaderboard[i][:sf_count] = "#{sf > 0 ? 'Yes' : 'No'}"
        @leaderboard[i][:sc_count] = "#{sc}"
        @leaderboard[i][:last_activity] = "#{la ? la : '[None]'}"
        @leaderboard[i][:last_reminded] = "#{lr ? lr : '[None]'}"

        i = i + 1
      end
    # end

    @leaderboard.sort! { |x,y| y[:ripple_effect_score] <=> x[:ripple_effect_score] }
  end

  def executive_report
    @company = current_user.company
    @leaderboard = Array.new()
    i = 0
    @team = @company.teams.find_by(id: params[:team])
    team_members = @team.present? ? @team.members : @company.all_members
    team_members.rippler.active.each do |m|
      # Leaderboard
      ic = SurveyPlan.for_others.where("giver_id = ? and state = 'active'", m.id).count
      os = Survey.for_others.open.where("giver_id = ?", m.id).count
      sf = Survey.for_self.scorable.where("giver_id = ?", m.id).count
      sc = Survey.for_others.scorable.where("giver_id = ?", m.id).count
      la = Survey.for_others.scorable.select("id, giver_id, date(completed_at)"). \
        where("giver_id = ?", m.id). \
        group("giver_id, date(completed_at)"). \
        order("date(completed_at) DESC"). \
        count("id").first
      lr = "#{m.last_reminded_at}"

      cm = m.company.parent_characteristics.first
      @score_reporter = Ripple::CharacteristicScoreReporter.new(m, cm)
      if @score_reporter.fetch_all_scores
        ripple_effect_score = @score_reporter.personal_scores.first[:scores][:overall]
      else
        ripple_effect_score = 0
      end
      @leaderboard[i] =
       {
        :leader_score => '',
        :company_id => '',
        :user_id => '',
        :user_name => '',
        :sp_count => '',
        :os_count => '',
        :sf_count => '',
        :sc_count => '',
        :last_activity => '',
        :last_reminded => '',
        :bad_pass_count => '',
        :reset_pass_count => ''
      }
      @leaderboard[i][:ripple_effect_score] = sprintf("%5.1f", ripple_effect_score)
      @leaderboard[i][:company_id] = "#{@company.id}"
      @leaderboard[i][:user_id] = "#{m.id}"
      @leaderboard[i][:user_name] = "#{m.full_name}"
      @leaderboard[i][:sp_count] = "#{ic}"
      @leaderboard[i][:os_count] = "#{os}"
      @leaderboard[i][:sf_count] = "#{sf > 0 ? 'Yes' : 'No'}"
      @leaderboard[i][:sc_count] = "#{sc}"
      @leaderboard[i][:last_activity] = "#{la ? la : '[None]'}"
      @leaderboard[i][:last_reminded] = "#{lr ? lr : '[None]'}"
      @leaderboard[i][:bad_pass_count] = "#{m.bad_password_count}"
      @leaderboard[i][:reset_pass_count] = "#{m.reset_password_count}"
      i = i + 1
    end
  end
end