# Provide simpler means for authenticated users to edit user profile and passwords
# without invoking Devise RegistrationsController#UpdateWithConfusionAndSuffering

class ProfilesController < ApplicationController

  def edit_profile
    @user = current_user
  end

  def update_profile
    @user = current_user
    user_params = params[:user].permit(:first_name, :last_name, :start_date, :department, :gender, :age, :cohort)
    if @user.update_attributes(user_params)
      redirect_to dashboard_path
    else
      render 'edit_profile'
    end
  end

  def edit_password
    @user = current_user
  end

  def update_password
    @user = current_user
    user_params = params[:user].permit(:current_password, :password, :password_confirmation)
    if @user.update_with_password(user_params)
      @user.reset_password_count = @user.reset_password_count + 1
      @user.save
      sign_out(@user)
      sign_in(:user, @user)
      redirect_to dashboard_path
    else
      render 'edit_password'
    end
  end

  def teams
    @user = current_user
  end

  def disable_dashboard
    company = current_user.company
    company.set_config(:show_dashboard, params[:value])
    render json: 'success'
  end

end
