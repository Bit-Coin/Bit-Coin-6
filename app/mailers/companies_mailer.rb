class CompaniesMailer < BaseMailer
  helper :application
  include Devise::Controllers::UrlHelpers
  layout 'email'
  
  def welcome_to_beta(maven_id)
    @maven = User.find(maven_id)
    @token = @maven.send('set_reset_password_token')
    mail({to: @maven.email, subject: "[Ripple] You're Ready to Start Rippling!"})
  end
end
