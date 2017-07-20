class SubscriptionsController < ApplicationController
  
  before_filter :get_subscription
  layout 'bare'
  
  def show
    @sub_type = @subscription.plan.name.split('_')[0] # free, company, enterprise
  end
  
  # Cancel the subscription
  
  def destroy
    # TODO...
  end
  
  # Upgrade a free subscription to a paid subscription
  
  def upgrade
    @payment = Payment.new
  end
  
  def update_subscription
    begin
      new_plan_name = 'company_1'
      token = params[:stripe_token] || raise('Can not transact without stripe token')
      cs = Ripple::Subscription::CompanySubscription.new(@subscription)
      new_subscription = cs.change_stripe_plan(new_plan_name, token)
      flash[:notice] = "Your card was charged, and subscription upgraded."
      redirect_to subscription_path(new_subscription.record)
    rescue Stripe::CardError => e
      flash[:error] = e.message
      @payment = Payment.new
      render 'subscriptions/upgrade'
    end
  end
  
  # Update the payment method for an existing paid subscription
  
  def pay
    @payment = Payment.new
  end
  
  def update_payment
    begin
      token = params[:stripe_token] || raise('Can not transact without stripe token')
      cs = Ripple::Subscription::CompanySubscription.new(@subscription)
      subscription = cs.change_payment_method(token) # UNIMPLEMENTED!
      flash[:notice] = "Your payment method has been updated."
      redirect_to subscription_path(subscription.record)
    rescue Stripe::CardError => e
      flash[:error] = e.message
      @payment = Payment.new
      render 'subscriptions/pay'
    end
  end
  
  protected
  
  def get_subscription
    @subscription = current_user.company.subscriptions.active
    if @subscription.owner_id != current_user.id
      redirect_to dashboard_path and return
    end
  end
  
end