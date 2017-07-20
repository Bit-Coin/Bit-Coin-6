class Admin::CompanySurveySeriesController < AdminController
  respond_to :html, :json
  before_action :get_company_survey_series, only: [:edit, :update, :destroy]

  def new
    @company = Company.find(params[:company])
    @ss = SurveySeries.find(params[:survey_series]) if params[:survey_series]
    @css = @company.company_survey_series.new({
      survey_series: @ss,
      config: @ss.try(:default_config)
    })

    respond_to do |format|
      format.html
      format.json { render json: {survey_series: @ss}.to_json, status: 200}
    end
  end

  # => {"utf8"=>"✓",
  #  "authenticity_token"=>
  #   "tQ/jSD+BEuMu583f5DH5UCP08UyIFCj8+6HjVZpFZVvn6ib4zqb76zz/E6givUg2AnVNwAv+x0VbXO9acSgsLQ==",
  #  "company_survey_series"=>
  #   {"company"=>"28",
  #    "survey_series"=>"5",
  #    "config"=>
  #     "{\"for_self\":false,\"allow_comments\":true,\"hours_between_surveys\":2160}"},
  #  "commit"=>"Add",
  #  "controller"=>"admin/company_survey_series",
  #  "action"=>"create"}
  def create
    c = Company.find(params[:company_survey_series][:company])
    ss = SurveySeries.find(params[:company_survey_series][:survey_series])
    config = JSON.parse(params[:company_survey_series][:config])
    company_survey_series = c.company_survey_series.create({ survey_series: ss, config: config })
    if company_survey_series
      # Connect SurveyPlans but DO NOT send intro emails
      connector = Ripple::CompanyConnector.new(c, nil, company_survey_series)
      # give the boss (and only the boss) a self-survey
      theboss = c.maven

      # connect everyone else to the boss, but not to each other
      all_members = c.all_members.select { |m| m.id != theboss.id }
      if company_survey_series.for_self?
        users = []
        if c.teams.present?
          c.teams.map{ |team| team.members.map{|member| users << member } } 
        else 
          users = c.users.active
        end
        users.each do|user|
          connector.join_self(user)
        end
      elsif company_survey_series.for_others?
        connector.join_all
      end
      flash[:notice] = "Survey series was added"
      redirect_to [:admin, c], anchor: 'survey_series'
    else
      flash[:error] = "This survey series is already configured for this company."
      redirect_to :back
    end
  end

  def edit; end

  def update
    if @css.update_attributes(strong_params)
      flash[:notice] = "Updated"
      redirect_to [:admin, @css.company], anchor: 'survey_series'
    else
      flash[:error] = "Error"
      respond_with @css
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      @css.survey_plans.each { |sp| sp.delete! } # voids open surveys too
      @css.destroy
      flash[:notice] = "Survey Series was removed. Open surveys voided. Survey plans deleted."
      redirect_to [:admin, @css.company], anchor: 'survey_series'
    end
  end

  private

  def get_company_survey_series
    @css = CompanySurveySeries.find(params[:id])
    @company = @css.company
  end

  def strong_params
    # parse string back into hash
    params[:company_survey_series][:config] = eval(params[:company_survey_series][:config]).to_json \
      if params[:company_survey_series] && params[:company_survey_series][:config]
    params.require(:company_survey_series).permit(:survey_series_id, :config)
  end
end
