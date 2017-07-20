class CustomDeviseMailer < BaseMailer
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
  layout 'email'

  # WARNING! Devise needs to go. These mailers only work
  # for Users.  Will not work as-is for Admins.

  # Until we replace Devise completely, these signatures
  # need to stay this way.
  def confirmation_instructions(record, token, opts={})
    @resource = User.find(record['id'])
    @token = token
    mail(to: @resource.email, subject: '[Ripple] Please confirm your email')
  end

  def reset_password_instructions(record, token, opts={})
    @resource = User.find(record['id'])
    @token = token
    mail(to: @resource.email, subject: '[Ripple] Reset your password')
  end

  def unlock_instructions(record, token, opts={})
    raise 'Lockable not implemented for User'
  end

  #############
  
  # CUSTOM MAILERS

  def maven_signed_you_up(user_id)
    @user = User.find(user_id)
    @token = @user.send('set_reset_password_token')
    @maven = @user.team.try(:manager) ? @user.team.manager : @user.company.manager
    subject = "[Ripple] #{@maven.full_name} has invited you"
    mail(to: @user.email, subject: subject)
  end
  
  def remind_login_domain(email)
    @email = email
    @users = User.where(:email => email).active.rippler.includes(:company)
    mail(to: email, subject: "[Ripple] Your login links")
  end
  
  def activate_carecloud_receiver(user_id)
    @user = User.find(user_id)
    @token = @user.send('set_reset_password_token')
    @maven = @user.team.try(:manager) ? @user.team.manager : @user.company.manager
    subject = "[Ripple] Welcome to the Ripple pilot, #{@user.first_name}"
    mail(to: @user.email, subject: subject)
  end

  def activate_carecloud_giver(user_id)
    @user = User.find(user_id)
    @token = @user.send('set_reset_password_token')
    @maven = @user.team.try(:manager) ? @user.team.manager : @user.company.manager
    subject = "[Ripple] #{@maven.full_name} has invited you to give feedback"
    mail(to: @user.email, subject: subject)
  end

  def activate_r50_giver(user_id)
    @user = User.find(user_id)
    @token = @user.send('set_reset_password_token')
    @maven = @user.team.try(:manager) ? @user.team.manager : @user.company.manager
    subject = "[Ripple] #{@maven.full_name} has invited you to give feedback"
    mail(to: @user.email, subject: subject)
  end    

  def happy_new_year(user_id)
    @user = User.find(user_id)
    @year = Time.now.year
    subject = "[Ripple] Happy New Year from Ripple!"
    mail(to: @user.email, subject: subject)
  end
 end
