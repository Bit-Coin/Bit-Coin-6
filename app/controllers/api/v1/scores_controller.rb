class Api::V1::ScoresController < ApplicationController
  respond_to :json

  def scores
    params[:characteristic] ||= 'res_components'
    params[:scope] ||= 'personal'
    @series = []

    if %w(all individual).include? params[:scope]
      @series << { name: 'You', color: Chart::SERIES_COLORS[:pink], 
                   scores: current_user.scores(scope: 'personal', 
                   characteristic: params[:characteristic]) }
    end

    if %w(all team).include? params[:scope]
      @series << { name: 'Team', color: Chart::SERIES_COLORS[:blue], 
                    scores: current_user.scores(scope: 'team', 
                   characteristic: params[:characteristic]) }
    end

    if %w(all cohort).include? params[:scope]
      @series << { name: 'Cohort', color: Chart::SERIES_COLORS[:green], 
                    scores: current_user.scores(scope: 'cohort', 
                   characteristic: params[:characteristic]) }
    end

    if %w(all company).include? params[:scope]
      @series << { name: 'Company', color: Chart::SERIES_COLORS[:orange], 
                    scores: current_user.scores(scope: 'company', 
                   characteristic: params[:characteristic]) }
    end

    @series
  end
end
