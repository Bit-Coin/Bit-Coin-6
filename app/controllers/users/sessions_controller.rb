class Users::SessionsController < Devise::SessionsController

  after_action :after_login, :only => :create, if: 'Ripple::CompanyContext.is_set?'
  skip_before_action :require_company_context, :only => [:new, :create, :destroy, :set_subdomain,
    :forgot_login_domain]


  def new
    @user = User.new
    if session[:current_quote_index] && (session[:current_quote_index] != PagesHelper.quotes.length - 1)
      session[:current_quote_index] = session[:current_quote_index] + 1
    else
      session[:current_quote_index] = 0
    end
  end

  # POST /users/sessions
  def create
    if params[:domain].present?
      set_company_context(Company.find_by_stub(params[:domain]).id)
    else
      disambiguate_company
    end
    if Ripple::CompanyContext.is_set?
      super
    else
      SystemEvent.new.log_event!('bad_email', {severity: Event::NOTIFY,
        body: {'message' => "Attempted login with bad email #{params[:user][:email]}"}
      })
      flash[:notice] = 'Invalid email or password.'
      redirect_to new_user_session_path
    end
  end

  # DELETE /users/sessions
  def destroy
    Ripple::CompanyContext.clear
    super
  end

  def after_login
    if current_user.has_proxy?
      current_user.log_event!('admin_proxy')
    else
      current_user.well_look_whos_here!
    end

    if current_user.self_surveys.blank?
      company = Company.find_by_name(Ripple::Globals::TESTDRIVE_COMPANY_NAME)


      # Ripple::OnboardUser.new(current_user).test_drive(company, true)

    end
  end

  def after_sign_in_path_for(resource)
    path = '/invitations/confirm_domain' if resource.prompt_for_company_domain?
    path ||= '/invitations/manage' \
      if resource.sign_in_count == 1 && !resource.company.settings[:consultant_mode]
    path ||= session[:user_return_to]
    path ||= '/dashboard'
    path
  end

  # GET /set_subdomain
  # set_subdomain_path
  def set_subdomain
  end

  # POST /find_login
  # find_login_path
  def find_login
    stub = params[:domain]
    company = Company.where(:stub => stub.downcase).first
    if company
      redirect_to login_url(:host => company.host)
    else
      flash[:error] = 'Sorry, we could not find that Ripple Crew.'
      render 'new'
    end
  end

  # GET /forgot_login_domain
  # forgot_login_domain_path
  def forgot_login_domain
  end

  # POST /remind_login_domain
  # remind_login_domain
  def remind_login_domain
    @email = params[:email]
    if @email.present?
      user_cnt = User.where(:email => @email).active.rippler.count
      if user_cnt > 0
        CustomDeviseMailer.remind_login_domain(@email).deliver!
        flash[:notice] = "Check your email. We sent a message to #{@email} with links to sign in to your Ripple Crews."
        render 'new'
      else
        flash[:error] = "We could not find your email address #{@email} in any Ripple Crews."
        render 'forgot_login_domain'
      end
    else
      flash[:error] = "Please enter your email address"
      render 'forgot_login_domain'
    end
  end

  def set_company_context(company_id)
    company_ids_for_email = User.active.rippler.where('email = ?', params[:user][:email]).pluck(:company_id)
    if company_ids_for_email.include?(company_id)
      Ripple::CompanyContext.company = Company.find(company_id)
    else
      raise Ripple::ContextError.new('User not authorized for company')
    end
  end

  def disambiguate_company
    unless Ripple::CompanyContext.is_set?
      users = User.where('email = ?', params[:user][:email]).rippler.active

      # if there's only one email, this is easy
      if users.length == 1 && users[0].company_id.present?
        set_company_context(users[0].company_id)

      # otherwise...
      elsif users.length > 1
        company_ids_for_password = []
        users.each do |u|
          company_ids_for_password << u.company_id if u.valid_password?(params[:user][:password])
        end

        # if it matches only one password, use it
        if company_ids_for_password.length == 1
          set_company_context(company_ids_for_password[0])

        # otherwise, make the user indicate his domain
        elsif company_ids_for_password.length > 1
          user = OpenStruct.new({
            'email' => params[:user][:email],
            'password' => params[:user][:password],
            'remember_me' => params[:user][:remember_me]
          })
          render 'set_subdomain', layout: 'pages', locals: { user: user }
        end
      end
    end
  end

end
