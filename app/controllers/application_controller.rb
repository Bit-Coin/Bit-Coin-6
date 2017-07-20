class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  force_ssl unless Rails.env.development? || Rails.env.test?
  
  before_action :configure_devise_allowed_params, if: :devise_controller?
  before_action :check_browser_compatibility, :check_for_authentication_token, 
    :authenticate_user!
  # TODO Do not exempt CompanyContext from test suite!
  before_action :require_company_context, unless: Proc.new {
    Rails.env.test? || request.env["devise.mapping"] == Devise.mappings[:admin]
  }

  # after_sign_in_path_for(User) is in users/sessions_controller
  def after_sign_in_path_for(resource)
    if resource.kind_of?(Admin)
      session[:admin_return_to] || '/admin'
    else # only users who are already logged in hit this
      current_user.log_event!('sign_in')
      dashboard_path
    end
  end

  def subdomain_stub
    request.host.split('.').first.downcase
  end
  
  def require_company_context
    unless Ripple::CompanyContext.is_set?
      if current_user
        Ripple::CompanyContext.company = current_user.company
      else
        raise Ripple::ContextError.new("Company context not set")
      end
    end
  end

  def raise_not_found!
    raise ActionController::RoutingError.new('Not Found')
  end

  protected

  def check_for_authentication_token
    session[:tokenized?] = params[:user_email].present? && params[:user_token].present?
  end

  # TODO remove.  This is handled by profiles controller
  def configure_devise_allowed_params
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:mobile_phone, :first_name, :last_name, :hire_date,
               :password, :password_confirmation, :current_password,
               :use_sms)
    end
  end

  def check_browser_compatibility
    user_agent = UserAgent.parse(request.user_agent)
    if Ripple::Globals::UnsupportedBrowsers.detect { |browser| user_agent < browser }
      flash[:error] = "Sorry! We don't support #{user_agent.browser} #{user_agent.version}." +
        'Please use a recent version of Chrome, Firefox, Safari, or your smartphone for the best experience.'
    end
  end
end
