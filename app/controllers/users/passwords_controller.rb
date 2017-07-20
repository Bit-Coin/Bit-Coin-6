class Users::PasswordsController < Devise::PasswordsController

  skip_before_action :require_company_context

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    if successfully_sent?(resource) # resource.errors.empty?
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      # TODO handle UGs differently
      respond_with(resource)
    end
  end

  def edit
    flash.clear
    super
  end

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty? && resource.active_for_authentication?
      resource.unlock_access! if unlockable?(resource)
      set_flash_message(:notice, :updated) if is_flashing_format?
      Ripple::CompanyContext.company = resource.company
      sign_in(resource_name, resource)
      respond_with resource, location: after_reset_path(resource)
    else
      respond_with resource
    end
  end

  protected 

  def after_reset_path(resource)
    dashboard_path
  end
end
