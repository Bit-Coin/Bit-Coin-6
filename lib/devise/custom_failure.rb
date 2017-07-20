class Devise::CustomFailure < Devise::FailureApp

  def respond
    log_failure_event!
    super
  end

  protected

  def log_failure_event!
    user = User.find_by_email(params[:user][:email]) if params[:user]
    if user.present?
      user.bad_password_count = user.bad_password_count + 1
      user.save
      if user.rippler?
        message = "User #{user.id} #{user.email} bad password"
        message += ": '#{params[:user][:password]}'" if user.settings[:show_bad_password]
        user.log_event!('bad_password', {severity: Event::NOTIFY, body: {'message' => message}})
      end
    end
  end
end
