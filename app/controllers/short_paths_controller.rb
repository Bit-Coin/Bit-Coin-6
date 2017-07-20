class ShortPathsController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_action :require_company_context

  def redirect_to_expanded_path
    user = User.includes(:company).find_by_short_path(params[:short_path])
    Ripple::CompanyContext.company = user.company if user

    # If user is already authenticated and tries to follow an expired
    # path for himself (old bookmark perhaps), go ahead and let him in.
    if user && (user.valid_short_path?(params[:short_path]) ||
        user == current_user)
      sign_out(:user) if user != current_user
      user.log_event!('sign_in') # yes, even though it's tokenized
      redirect_to next_survey_url(user_email: user.email,
        user_token: user.authentication_token, host: user.company.host)

    elsif user && user.rippler?
      Ripple::CompanyContext.clear # paranoia
      user.log_event!('expired_short_path', { severity: Event::WARN, body: {
        message: "#{user.email} (Rippler) hit expired path #{params[:short_path]} and was prompted to sign in"}})
      session['user_return_to'] = next_survey_url(host: user.company.host)
      flash[:notice] = "Please sign in."
      redirect_to login_url(host: user.company.host)

    elsif user # allow unregistered_givers to use expired tokens
      user.log_event!('ug_short_path', { severity: Event::WARN, body: {
        message: "#{user.email} (UG) hit expired path #{params[:short_path]} and was allowed to continue."}})
      redirect_to next_survey_url(user_email: user.email,
        user_token: user.authentication_token, host: user.company.host)

    else
      # Log system event
      Ripple::CompanyContext.clear
      Ripple::EventLogger.new('missing_short_path', { severity: Event::INFO, body: {
        message: "Attempt to follow non-existent short path /#{params[:short_path]}"}}).log!
      raise_not_found!
    end
  end

  def swallow
    Ripple::CompanyContext.clear # paranoid
    render :file => "#{Rails.root}/public/404.html",  :status => 404
  end
end
