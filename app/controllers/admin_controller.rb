class AdminController < ActionController::Base
  protect_from_forgery with: :exception
  force_ssl if Rails.env.production?

  before_filter :authenticate_admin!
  
  # after_sign_in_path_for is in ApplicationController

end
