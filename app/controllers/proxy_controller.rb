class ProxyController < ApplicationController
  
  skip_before_filter :authenticate_user!
  skip_before_action :require_company_context
  
  # POST /proxy/become_proxy/:user_id
  # Become a proxy for the given user id
  
  def become_proxy
    authenticate_admin!
    return_to = request.env['HTTP_REFERER']
    user = User.find(params[:user_id])
    user.set_proxy!(current_admin)
    sign_out(current_admin)
    sign_in(:user, user)
    session[:proxy_secret] = user.proxy_secret
    session[:return_to] = return_to
    redirect_to dashboard_path
  end
  
  # POST /proxy/become_admin
  # Discard proxy for current_user and become admin again
  
  def become_admin
    authenticate_user!
    if current_user.proxy && current_user.proxy_secret === session[:proxy_secret]
      # Session is OK to revert to admin, because secrets match.
      proxy = current_user.proxy
      user = current_user
      current_user.discard_proxy!
      sign_out(current_user)
      sign_in(:admin, proxy)
      flash[:notice] = "Signed out of #{user.email}. Signed back in as #{proxy.email}."
      redirect_to session[:return_to] || admin_path
    else
      # Bad person. Eject seat. https://www.youtube.com/watch?v=nOovz9heQ6I
      current_user.discard_proxy!
      sign_out(current_user)
      flash[:error] = 'Please log in'
      redirect_to new_admin_session_path
    end
  end
end