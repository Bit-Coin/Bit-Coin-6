# Less Tortured Registration Flow

# 1.  Provide email, submit

# 2.  If email is already taken
#       - land on login page with flash message "Email is already registered"
#       - END

#     If email is missing
#       - return to email entry page
#       - flash error "You must enter an email"
#       - END

#     If email is not in list of registered companies
#       - show notice about closed beta while waiting for confirmation email
#       - click confirmation link
#       - collect first/last names
#       - collect company name
#       - submit
#       - return Thanks, we'll let you know when we're ready for you
#       - END

#     Else new registrant at beta company
#       - confirm email
#       - show company name (not editable)
#       - collect first/last names
#       - choose/confirm password
#       - submit, land on login page

# 3.  Log in, land on /invitations/manage
#       - END

class Users::RegistrationsController < Devise::RegistrationsController

  before_action :set_user, except: [:register_email, :create_user_stub]
  skip_before_action :require_company_context

  # GET /register/email
  def register_email
    @user = User.new
  end

  # POST /register/email
  def create_user_stub
    if params[:user][:email].blank? || params[:user][:email_confirmation].blank?
      flash[:error] = "You must enter your email twice"
      @user = User.new
      render 'devise/registrations/register_email'
      return
    end

    unless params[:user][:email] == params[:user][:email_confirmation]
      @user = User.new(email: params[:user][:email])
      flash[:error] = "Emails don't match"
      @user = User.new
      render 'devise/registrations/register_email'
      return
    end
    
    email = params[:user][:email]
    @user = User.find_by_email(email)
    if @user.blank?
      domain = email.split('@')[1]
      company = Company.find_by_domain(domain)
      if company
        @user = User.create!({
          :email => email,
          :unconfirmed_email => email,
          :password => SecureRandom.password,
          :company => company,
          :team => nil,
          :type => User::RIPPLER,
          :state => User::ACTIVE
        })
        render 'devise/registrations/confirm_rippler_email' and return
      else
        @user = User.create!({
          :email => email,
          :unconfirmed_email => email,
          :pending_company_name => 'Unknown',
          :password => SecureRandom.password
        })
        render 'devise/registrations/confirm_contact_email' and return
      end

    elsif @user.rippler?
      flash[:error] = "#{@user.email} is already registered."
      redirect_to login_path and return

    elsif @user.unregistered_giver?
      flash[:notice] = 'Please complete your registration.'
      redirect_to register_rippler_path(id: @user.id) and return

    elsif @user.prospect?
      flash[:notice] = "#{@user.email} has already requested access. Someone from Ripple will be in touch when the beta period is open."
      redirect_to thank_you_contact_path(id: @user.id) and return

    else
      # unknown user type
      raise 'I am very confused.'
    end
  end
  
  # GET /contact/:id/register
  def contact_form
    # TODO disallow unless fields are empty
  end

  # PUT /contact/:id/register
  def create_pending_registration
    # TODO don't overwrite existing values (or else
    # anyone can change your contact info)
    company_name = params[:company_name].blank? ? @user.pending_company_name : params[:company_name]
    @user.update_attributes(
      first_name: params[:first_name],
      last_name: params[:last_name],
      type: User::PROSPECT,
      state: User::ACTIVE,
      pending_company_name: company_name
    )

    if @user.pending_company_name != 'Unknown'
      message = "#{@user.full_name} (#{@user.email}) at #{@user.pending_company_name} wants to Ripple!!!"
    else
      message = "#{@user.full_name} (#{@user.email}) wants to Ripple!!!"
    end
    logger = Ripple::ActivityLogger.new(:text => message, :icon_emoji => ':green_heart:')
    logger.log!
    
    redirect_to thank_you_contact_path(id: @user.id)
  end

  # GET /contact/:id/thank_you
  def thank_you
  end

  # GET /rippler/:id/register
  def rippler_form
    if @user.rippler? && @user.sufficiently_registered?
      flash[:error] = 'User is already registered. Please log in.'
      redirect_to login_path and return
    end
  end

  # PUT /register/:id/rippler
  def create_rippler_registration
    raise_not_found! if @user.rippler? && @user.sufficiently_registered?
    raise_not_found! if @user.company.nil?
    
    if @user.company.subscriptions.active.nil?
      raise("Rippler can not register for this company right now, as there is no subscription")
    end
    
    changes = {
      :first_name => params[:first_name],
      :last_name => params[:last_name],
      :password => params[:password],
      :password_confirmation => params[:password_confirmation],
      :confirmed_at => DateTime.now
    }
    
    if @user.update_attributes(changes)
      company_subscription = Ripple::Subscription::CompanySubscription.new(@user.company.subscriptions.active)
      company_subscription.register_user(@user)
      
      sign_in(:user, @user)
      flash[:notice] = 'Registration successful!'
      message = "#{@user.email} registered a new account!"
      logger = Ripple::ActivityLogger.new(:text => message, :icon_emoji => ':new:')
      logger.log!
      redirect_to manage_invitations_path
    else
      render template: 'devise/registrations/rippler_form'
    end
  end

  def resend_surveys
    count = @user.surveys.open.count
    if count == 0
      flash[:notice] = 'There are no open surveys for this person.'
    elsif @user.redeliver_surveys
      flash[:notice] = "#{count} surveys were re-sent"
    else
      flash[:error] = 'Error resending surveys'
    end
    redirect_to :back
  end

  protected

  # Used by users/registration#update
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up).push(:first_name, :last_name)
  end

  def after_update_path_for(resource)
    edit_user_registration_path(resource)
  end

  def set_user
    @user = current_user || User.find(params[:id])
  end
end
