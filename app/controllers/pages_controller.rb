class PagesController < ApplicationController
  skip_before_filter :authenticate_user!, :require_company_context
  impressionist :actions=>[:ripple_innovative]
  layout 'pages'

  def home
    @user = User.new
    if session[:current_quote_index] && (session[:current_quote_index] != PagesHelper.quotes.length - 1)
      session[:current_quote_index] = session[:current_quote_index] + 1
    else
      session[:current_quote_index] = 0
    end
    if request.subdomain == "demo" && current_user.nil?
      redirect_to login_path
    end
  end

  def iphone
  end

  def terms_and_conditions
  end

  def privacy_policy
  end

  def board_of_trustees
  end

  def board_of_advisors
  end

  def blogs
    @blogs = Blog.all
  end

  def ripple_innovative

  end

  def blog
    @blog = Blog.find(params[:id])
  end
end
