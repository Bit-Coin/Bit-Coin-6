class StripeWebhooksController < ActionController::Base
  
  skip_before_filter :protect_from_forgery
  
  # Configure in stripe to receive the following webhooks:
  # invoice.created
  # invoice.payment_failed
  # invoice.payment_succeeded
  # invoice.updated
  #
  # This processor keeps invoice records up to date with the current state of all invoices in Stripe
  
  def invoice_events
    require_event_type('invoice')
    subscription_id = params['data']['object']['subscription']
    subscription = Subscription.find_by_stripe_subscription_id(subscription_id)
    stripe_invoice_id = params['data']['object']['id']
    invoice = Invoice.where(:stripe_invoice_id => stripe_invoice_id).first
    if (invoice)
      invoice.update_attributes(:body => params['data']['object'])
    else
      Invoice.create({
        :subscription_id => subscription.id,
        :company_id => subscription.company_id,
        :stripe_invoice_id => stripe_invoice_id,
        :body => params['data']['object']
      })
    end
    invoice_hook = params['type'].split('.')[1]
    subscription.update_state_for_invoice_hook(invoice_hook, params['data']['object'])
    subscription.record_event_for_invoice_hook(invoice_hook, params['data']['object'])
    head :no_content
  end
  
  # Configure in stripe to receive the following webhooks:
  # charge.succeeded
  # charge.failed
  #
  # I am not sure we need these. Perhaps invoice.payment_succeeded and payment_failed are enough

  def charge_events
    require_event_type('charge')
    head :no_content
  end
  
  protected
  
  def require_event_type(t1, t2=nil)
    p1, p2 = params['type'].split('.')
    if t1 != p1
      raise "Event type is not #{t1}"
    end
    if t2 && t2 != p2
      raise "Event type is not #{t1}.#{t2}"
    end
  end
  
end