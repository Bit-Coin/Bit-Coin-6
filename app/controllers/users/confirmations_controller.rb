class Users::ConfirmationsController < Devise::ConfirmationsController

  skip_before_action :require_company_context

  def after_confirmation_path_for(resource_name, resource)
    if resource.rippler?
      rippler_form_path(id: resource.id)
    else
      contact_form_path(id: resource.id)
    end
  end
end
