class Admin::SurveySetsController < AdminController
  respond_to :html
  before_action :get_survey_set, only: [:update, :edit, :destroy]
  before_action :catch_cancel, only: [:update, :create]

  def new
    @survey_set = SurveySeries.find(params[:ss]).survey_sets.build
    @survey_set.assign_default_position
  end

  def edit; end

  def create
    @survey_set = SurveySet.create(strong_params)
    if @survey_set.persisted?
      flash[:notice] = 'Created'
      redirect_to edit_admin_survey_series_path(@survey_set.survey_series)
    else
      flash[:error] = 'Error'
      respond_with @survey_set 
    end
  end

  def update
    if @survey_set.update_attributes(strong_params)
      flash[:notice] = 'Updated'
      redirect_to edit_admin_survey_series_path(@survey_set.survey_series)
    else
      flash[:error] = 'Error'
      respond_with @survey_set
    end
  end

  def destroy
    if @survey_set.survey_set_questions.any?
      ActiveRecord::Base.transaction do
        @survey_set.surveys.open.update_all(state: 'void')
        @survey_set.survey_set_questions.destroy_all
        @survey_set.update_attributes(state: 'deleted')
      end
    else
      @survey_set.destroy
    end
    flash[:notice] = 'Deleted'
    redirect_to edit_admin_survey_series_path(@survey_set.survey_series)
  end

  private

  def get_survey_set
    @survey_set = SurveySet.find(params[:id])
  end

  def strong_params
    params.require(:survey_set).permit(:name, :state, :survey_series_id, :position)
  end

  def catch_cancel
    if params[:commit] == 'Cancel'
      flash[:notice] = 'Operation canceled'
      redirect_to edit_admin_survey_series_path(id: params[:survey_set][:survey_series_id])
    end
  end
end
