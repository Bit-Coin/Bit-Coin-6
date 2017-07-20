class Admin::UsersController < AdminController
  
  # Filters:
  # company_id
  # state
  # confirmed_at
  
  # GET /admin/users
  def index
    scope = User.order('created_at desc').includes(:company)
    if params[:name].present?
      @name = params[:name].downcase
      scope = scope.where("LOWER(first_name) like '%#{@name}%' OR LOWER(last_name) like '%#{@name}%'")
    end
    if params[:company_id].present?
      @company_id = params[:company_id].to_i
      scope = scope.where(:company_id => @company_id)
    end
    if params[:state].present?
      @state = params[:state].downcase
      scope = scope.send(@state)
    end
    if params[:confirmed_at].present?
      scope = scope.where('confirmed_at is not null')
    end
    @total_users = scope
    scope = scope.page(params[:page]).per(50)
    @users = scope
  end

  def team_leaders
    scope = User.order('created_at desc').includes(:company).joins(:manage_teams).uniq
    if params[:company_id].present?
      @company_id = params[:company_id].to_i
      scope = scope.where(:company_id => @company_id)
    end
    if params[:state].present?
      @state = params[:state].downcase
      scope = scope.send(@state)
    end
    if params[:confirmed_at].present?
      scope = scope.where('confirmed_at is not null')
    end
    scope = scope.page(params[:page]).per(600)
    @users = scope
  end

  # GET /admin/users/prospects
  def prospects
    @prospects = User.prospect.active.order(:id)
  end

  # GET /admin/users/reminders
  def reminders
    sql_string = <<-SQL
      select 
        date(users.last_reminded_at) as date_last_reminded,
        state as user_state,
        type as user_type,
        count(users.id) as num_users
      from users 
      where type in ('rippler', 'unregistered_giver')
      group by date_last_reminded, user_state, user_type
      order by date_last_reminded desc
    SQL
    @table = ActiveRecord::Base.connection.exec_query sql_string
  end

  # GET /admin/users/:id/new_contact
  def new_contact
  end

  # POST /admin/users/:id/create_contact
  def create_contact
    user = Ripple::OnboardUser.create_prospect(
      params[:first_name], params[:last_name], params[:email], params[:pending_company_name]
    )
    flash[:notice] = "Created new prospect #{user.full_name} (#{user.email}) with user ID #{user.id}"
    redirect_to prospects_admin_users_path
  end

  # GET /admin/users/:id/test_drive
  def test_drive
    @driver = User.find(params[:id])
    @company = Company.find_by_name(Ripple::Globals::TESTDRIVE_COMPANY_NAME)
    raise "Cannot find #{Ripple::Globals::TESTDRIVE_COMPANY_NAME} for test driving" if @company == nil
  end

  # POST /admin/users/:id/connect_test_driver
  def connect_test_driver
    driver = User.find(params[:id])
    company = Company.find_by_name(Ripple::Globals::TESTDRIVE_COMPANY_NAME)
    ActiveRecord::Base.transaction do
      driver.update_attributes(params.permit(:first_name, :last_name))
      Ripple::OnboardUser.new(driver).test_drive(company, true)
      CompaniesMailer.welcome_to_beta(driver.id).deliver!
    end
    message = "#{driver.full_name} is now test driving as part of #{company.name}!"  
    Ripple::ActivityLogger.new(:text => message, :icon_emoji => ':car:').log!     
    flash[:notice] = message
    redirect_to prospects_admin_users_path
  end
  
  # GET /admin/users/:id/new_company
  def new_company
    @maven = User.find(params[:id])
    @company = Company.new
  end

  # POST /admin/users/:id/new_company
  def create_company
    user = User.find(params[:id]) # that's our maven
    company = Ripple::OnboardUser.new(user).create_company(params[:name], params[:domain], params[:stub])

    # default add Ripple50 company survey series
    company.use_series(1, allow_comments: true)
    company.use_series(2)
    
    message = "Created new company #{company.name} with #{user.full_name} as maven"
    flash[:notice] = message
    Ripple::ActivityLogger.new(text: message, icon_emoji: ':smile_cat:').log!
    redirect_to prospects_admin_users_path
  end

  # DELETE /admin/users/:id/destroy
  def destroy
    @user = User.find(params[:id])
    if @user.delete!
      flash[:notice] = "#{@user.full_name} #{@user.email} was deleted."
    else
      flash[:error] = "#{@user.full_name} could not be deleted."
    end
    if params[:return] == "user_reports"
      redirect_to "/admin/users"
    else
      redirect_to prospects_admin_users_path
    end
  end

  def set_feedback_option
    user = User.find_by(id: params[:id])
    user.update_attributes(feedback_type: params[:type])
    respond_to do |format|
      format.js { flash[:notice] = "User has been updated successfully." }
    end
  end

  def destroy_final
    @user = User.find(params[:id])
    if @user.destroy
      flash[:notice] = "#{@user.full_name} #{@user.email} was permanently deleted."
    else
      flash[:error] = "#{@user.full_name} could not be deleted."
    end
    redirect_to "/admin/users"
  end

  def edit
    @user = User.find_by_id(params[:user_id])
  end

  def update
    @user = User.find_by_id(params[:user][:user_id])
    user_params = params[:user].permit(:first_name, :last_name)
    @user.update_attributes(user_params)
    if params[:user][:team].present?
      teams = Team.where(:id => params[:user][:team])
      # @user.team_managers.destroy_all
      teams.each do |team|
        team_member = TeamMember.find_or_initialize_by(:team_id => team.id, :user_id => @user.id)
        team_member.is_manager = true
        team_member.save
        # existing_team = TeamMember.where()
        # TeamManager.create(:team_id => team.id, :manager_id => @user.id)
      end
    end
    redirect_to "/admin/users/#{@user.id}"
  end

  def edit_password
    @user = User.find_by_id(params[:user_id])
  end

  def update_password
    @user = User.find_by_id(params[:user][:user_id])
    if params[:user][:password] == params[:user][:password_confirmation]
      if @user.update(:password => params[:user][:password])
        flash[:notice] = "Password has been changed successfully"
      else
        @user.errors.add(:password, "has not changed")
      end
    else
      @user.errors.add(:password, "confirmation doesn't match Password")
    end
    redirect_to admin_company_path(@user.company)
  end
  
end
