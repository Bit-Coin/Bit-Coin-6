class Admin::CompaniesController < AdminController
  def show
    @company = Company.find(params[:id])
    @survey_ids = @company.surveys.pluck(:id)
    @settings = @company.settings

    sql_string = <<-SQL
      select
        date(surveys.created_at) as date_created,
        surveys.state as survey_state,
        count(surveys.id) as count
      from surveys
      where surveys.id in ( #{@survey_ids.join(',')} )
      group by date_created, survey_state
      order by date_created DESC
    SQL
    @table = @survey_ids.any? ? ActiveRecord::Base.connection.exec_query(sql_string) : [{data: 'No Data'}]
    survey_plans = @company.survey_plans.select {|s| s.giver == s.receiver}.uniq
    users = @company.users - survey_plans.collect(&:giver)
    @users = users.select {|u| u.user_roles.present?}
  end

  def new
    @company = Company.new
  end

  def edit
    @company = Company.find(params[:id])
  end

  def create
    raise('Stop. Use Ripple::OnboardUser or Ripple::Subscription::CompanySubscription')
  end

  def update
    @company = Company.find(params[:id])
    @company.update_attributes(strong_params)
    redirect_to :back
  end

  def destroy
    @company = Company.find(params[:id])
    @company.destroy
    flash[:notice] = "Company '#{@company.name}' has been deleted."
    redirect_to "/admin"
  end

  def update_config
    @company = Company.find(params[:id])
    @company.set_config(:months_between_self_surveys, params[:months_between_self_surveys].to_i)
    @company.set_config(:weeks_with_weekly_surveys, params[:weeks_with_weekly_surveys].to_i)
    @company.set_config(:spoof_receiver_email, params[:spoof_receiver_email] === '1')
    @company.set_config(:consultant_mode, params[:consultant_mode] === '1')
    @company.set_config(:access_development_tools, params[:access_development_tools] === '1')
    @company.set_config(:accelerated_surveys, params[:accelerated_surveys] === '1')
    @company.set_config(:hyperspeed, params[:hyperspeed] === '1')
    flash[:notice] = 'New company settings saved'
    redirect_to admin_company_path(@company, :anchor => "settings")
  end

  def create_team
    @company = Company.find(params[:id])
    @team = @company.teams.create!(params.permit(:name))
    flash[:notice] = 'New team saved'
    redirect_to admin_company_path(@company, :anchor => "teams")
  end

  def new_executive
    @company = Company.find_by(id: params[:id])
  end

  def add_executive
    company = Company.find_by(id: params[:id])
    user = company.users.find_by(id: params[:executive])
    user.add_role("executive")
    redirect_to admin_company_path(company), notice: "Executive added successfully"
  end

  def assign_team
    @company = Company.find(params[:id])
    @users = @company.users.where(id: params[:user_id].reject{|t|t.empty?})
    @team = @company.teams.find(params[:team_id])
    @users.each do |user|
      team_member = TeamMember.find_or_initialize_by(:team_id => @team.id, :user_id => user.id)
      team_member.save
    end
    if @users.present?
      @team.team_members.where("user_id NOT IN (?)", @users.collect(&:id)).destroy_all
    else
      @team.team_members.delete_all
    end
    redirect_to admin_company_path(@company, :anchor => "teams")
  end

  def assign_team_manager
    @company = Company.find(params[:id])
    @user = @company.users.find(params[:user_id])
    @teams = @company.teams.where(id: params[:team_id].reject{|t|t.empty?})
    @teams.each do |team|
      team_member = TeamMember.find_or_initialize_by(:team_id => team.id, :user_id => @user.id)
      team_member.is_manager = true
      team_member.save
    end
    @user.team_members.where.not(:team_id => @teams.map(&:id)).update_all(:is_manager => false)
    redirect_to admin_company_path(@company, :anchor => "team_managers")
  end

  def change_user_state
    user = User.find(params[:user_id])
    @company = Company.find(params[:id])
    user.state = params[:state]
    if user.save
      flash[:notice] = "Successfully changed #{user.email}'s state"
    else
      flash[:error] = "Something went wrong please try again later"
    end
    redirect_to admin_company_path(@company)
  end

  def bulk_create_users
    result = onboard_users
    if result[:users].length > 0
      flash[:notice] = "Successfully created #{result[:users].length} new users, with #{result[:survey_plans].length} new survey plans"
    end
    if result[:invalid_rows].length > 0
      flash[:error] = "There were #{result[:invalid_rows].length} invalid rows. Users were not created."
    end
    redirect_to admin_company_path(@company)
  end

  def connect_users
    result = onboard_users
    if result[:users].length > 0
      flash[:notice] = "Successfully connected users, with #{result[:survey_plans].length} new survey plans"
    end
    if result[:invalid_rows].length > 0
      flash[:error] = "There were #{result[:invalid_rows].length} invalid rows. Users were not created."
    end
    redirect_to admin_company_path(@company)
  end

  def update_development_tools
    user = User.find(params[:id])
    user.access_development_tools = !user.access_development_tools
    user.save
    render json: {success: true}
  end

  def new_maven
    @company = Company.find(params[:id])
  end

  def update_maven
    @company = Company.find(params[:company_id])
    @maven = @company.update_attributes(manager_id: params[:id])
    flash[:notice] = "Successfully added #{@company.maven.full_name} as maven"
    redirect_to admin_company_path(@company)
  end

  def generate_self_survey
    company = Company.find(params[:id])
    users = User.where(id: params[:user_id].reject{|t|t.empty?})
    css_for_self = company.company_survey_series.for_self.order(created_at: :desc)
    css_for_self.each do |css|
      users.each do |user|
        user.default_user_role.invite!(user, state: 'active', company_survey_series: css)
      end
    end
    flash[:notice] = "Survey plans created successfully"
    redirect_to admin_company_path(company)

  end

  protected

  def onboard_users
    @company = Company.find(params[:id])
    @team = params[:team_id].present? ? @company.teams.find(params[:team_id]) : nil

    Ripple::OnboardUser.create_ripplers_from_csv(@company, @team, params[:csv], {
      :connect_maven => params[:connect_maven] === '1',
      :connect_all => params[:connect_all] === '1'
    })
  end

  def strong_params
    params.require(:company).permit(:name, :domain, :ripple_api_key, :ripple_api_token)
  end
end
