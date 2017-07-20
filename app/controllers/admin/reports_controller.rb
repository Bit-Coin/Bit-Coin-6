class Admin::ReportsController < AdminController

  def system_reports
    scope = Company.order('id asc')
    if params[:company_id].present?
      @company_id = params[:company_id].to_i
      scope = scope.where(:id => @company_id)
    end
    @companies = scope

    @leaderboard = Array.new()
    @scores = Array.new()

    i = 0
    j = 0

    @companies.each do |c|
      c.all_members.rippler.active.each do |m|
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

        Survey.scorable.where("giver_id = ?", m.id).each do |s|
          rscore = Response.where("survey_id = ?", s.id).count
          created_at = s.created_at
          completed_at = s.completed_at
          if completed_at < (created_at + 1.day + 1.second)
            multiplier = 1.2
            b20_surveys = b20_surveys + 1
          elsif completed_at < (created_at + 3.days + 1.second)
            multiplier = 1.1
            b10_surveys = b10_surveys + 1
          else
            multiplier = 1.0
          end

          tot_surveys = tot_surveys + 1
          score = score + rscore * multiplier
        end # Survey

        leader_score = score

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

        @leaderboard[i][:leader_score] = sprintf("%5.1f", leader_score)
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
    end

    @leaderboard.sort! { |x,y| y[:leader_score] <=> x[:leader_score] }
  end


  def user_reports
    scope = Company.order('id asc')
    if params[:company_id].present?
      @company_id = params[:company_id].to_i
      scope = scope.where(:id => @company_id)
    end
    @companies = scope

    @leaderboard = Array.new()
    @companyboard = Array.new()

    i = 0

    @companies.each do |c|
      c.all_members.rippler.active.each do |m|
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

        @leaderboard[i] =
         {
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

        @leaderboard[i][:company_id] = "#{c.id}"
        @leaderboard[i][:user_id] = "#{m.id}"
        @leaderboard[i][:user_name] = "#{m.first_name}"
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


  def user_system_reports
    @user = User.find_by_id(params[:user_id])
    @competency_models = @user.company.parent_characteristics
    @all_cm_scores = {}
    @published_at = nil
    @competency_models.each do |cm|
      @score_reporter = Ripple::CharacteristicScoreReporter.new(@user, cm)
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

  def questions
    @user = User.find_by_id(params[:user_id])
    pcid = params[:cm_id]
    @score_reporter = Ripple::QuestionScoreReporter.new(@user, pcid)
    @has_scores = @score_reporter.fetch_all_scores
    if @has_scores
      @res = {
        :personal => @score_reporter.personal_scores,
        :company => @score_reporter.company_scores,
        :self => @score_reporter.self_scores
      }
      @general_comments = @user.comments.general
    else
      @res = false
    end
  end

  def impression_count

  end


end
