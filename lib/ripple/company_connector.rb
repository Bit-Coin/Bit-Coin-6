module Ripple

  # This class generates a fully connected graph inside a company or team
  # All join methods return an array of newly created SurveyPlans

  class CompanyConnector

    attr_reader :company, :team, :company_survey_series

    def initialize(company, team=nil, company_survey_series=nil)
      @company = company
      @team = team
      @company_survey_series = company_survey_series
    end

    def join_all
      if @team.present?
        join_groups(@team.members.active, @team.members.active)
      elsif @company.teams.present?
        @company.teams.each do |team|
          join_groups(team.members.active, team.members.active)
        end
      else
        join_groups(@company.users.active, @company.users.active)
      end
    end

    # Bi-directional many-to-one
    def join_to_maven(group)
      join_groups([maven], group)
    end

    # Unidirectional many_to_one
    def give_to_maven(group)
      group.each do |g|
        maven.default_user_role.invite!(g, state: 'active',
          company_survey_series: @company_survey_series)
      end
    end

    def join_groups(left_group, right_group)
      new_plans = []
      left_group.each do |left_user|
        next unless left_user.rippler?
        right_group.each do |right_user|
          next unless right_user.rippler?
          new_plans.concat join_users(left_user, right_user)
        end
      end
      (left_group + right_group).uniq.each do |user|
        Resque.enqueue(Job::CreateUserSurveys, user.id)
      end
      new_plans
    end

    def join_self(user)
      @company_survey_series = @company_survey_series.persisted? ? @company_survey_series : CompanySurveySeries.where(survey_series_id: @company_survey_series.survey_series_id, state: @company_survey_series.state,company_id: @company.id).first
      if user.default_user_role.present?
        user.default_user_role.invite!(user, state: 'active',
          company_survey_series: @company_survey_series)
        Resque.enqueue(Job::CreateUserSurveys, user.id)
      end
    end

    def join_users(left_user, right_user)
      return [] if left_user == right_user
      new_plans = []
      unless SurveyPlan.for_pair(left_user, right_user, @company_survey_series).not_dead.any?
        new_plans << right_user.default_user_role.invite!(left_user, state: 'active',
          company_survey_series: @company_survey_series)
      end
      unless SurveyPlan.for_pair(right_user, left_user, @company_survey_series).not_dead.any?
        new_plans << left_user.default_user_role.invite!(right_user, state: 'active',
          company_survey_series: @company_survey_series)
      end
      new_plans
    end

    def maven
      @maven ||= @team ? @team.manager : @company.manager
    end

  end
end
