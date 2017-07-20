class Admin::SurveySeriesController < AdminController
  respond_to :html
  before_action :get_survey_series, only: [:edit, :update, :destroy]
  before_action :catch_cancel

  def index
    @survey_series = SurveySeries.all
  end

  def new
    @survey_series = SurveySeries.new({
      default_config: {"for_self"=>false, "allow_comments"=>true, "hours_between_surveys"=>2160}
    })
  end

  def create
    @survey_series = SurveySeries.create(strong_params)
    if @survey_series.id
      @survey_series.survey_sets.create({name: 'Default'})
      flash[:notice] = "Created"
      redirect_to '/admin/survey_series'
    else
      flash[:error] = "Error"
      respond_with @survey_series
    end
  end

  def edit; end

  def update
    if @survey_series.update_attributes(strong_params)
      flash[:notice] = "Updated"
      redirect_to '/admin/survey_series'
    else
      flash[:error] = 'Error'
      respond_with @survey_series
    end
  end

  def destroy
    unless @survey_series.companies.any?
      ActiveRecord::Base.transaction do 
        @survey_series.survey_sets.destroy_all
        @survey_series.destroy
      end
      flash[:notice] = "Deleted"
    else
      flash[:error] = "This Survey Series is in use.  Delete all Company Survey Series first."
    end
    redirect_to '/admin/survey_series'
  end

  private

  def get_survey_series
    @survey_series = SurveySeries.find(params[:id])
  end

  def strong_params
    # parse string back into hash
    params[:survey_series][:default_config] = eval(params[:survey_series][:default_config]).to_json \
      if params[:survey_series] && params[:survey_series][:default_config]
    params.require(:survey_series).permit(:name, :description, 
      :parent_characteristic_id, :default_config)
  end

  def catch_cancel
    if params[:commit] == 'Cancel'
      flash[:notice] = 'Operation canceled'
      redirect_to '/admin/survey_series' and return
    end
  end
end
