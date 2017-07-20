class Admin::SubscriptionsController < AdminController
  
  before_filter :get_company
  
  def index
    @subscriptions = @company.subscriptions
  end
  
  def new
    @subscription = @company.subscriptions.build({
      :state => Subscription::PENDING
    })
  end
  
  def create
    @subscription = @company.subscriptions.build(strong_params)
    @subscription.owner = @company.manager
    if @subscription.save
      redirect_to admin_company_path(@company)
    else
      render 'new'
    end
  end
  
  def edit
    get_subscription
  end
  
  def update
    get_subscription
    if @subscription.update_attributes(strong_params)
      redirect_to admin_company_path(@company)
    else
      render 'update'
    end
  end
  
  def destroy
    get_subscription
    @subscription.update_attributes!({
      :state => Subscription::CANCELED,
      :end_at => DateTime.now
    })
    redirect_to admin_company_path(@company)
  end
  
  def upgrade
    get_subscription
    @payment = Payment.new
  end
  
  # e.g. "stripe_token" => "tok_15rcHzAJkB8dJrsD4fZvij79"
   
  def transact
    get_subscription
    token = params[:stripe_token] || raise('Can not transact without stripe token')
    plan = Plan.find(params[:payment][:plan_id])
    
    cs = Ripple::Subscription::CompanySubscription.new(@subscription)
    new_subscription = cs.change_stripe_plan(plan.name, token)
    flash[:notice] = "Customer was charged, and subscription upgraded."
    redirect_to admin_company_path(@company)
  end
  
  protected
  
  def get_company
    @company = Company.find(params[:company_id])
  end
  
  def get_subscription
    @subscription = @company.subscriptions.find(params[:id])
  end
  
  def strong_params
    params.require(:subscription).permit(:plan_id, :start_at, :end_at, :state)
  end
  
end