require 'securerandom'

module Ripple
  module Subscription
    
    class CompanySubscription < BaseSubscription
      
      DEFAULT_PLAN = 'free_trial_1'
      
      # Adds an existing user to a subscription
      
      def register_user(user)
        ActiveRecord::Base.transaction do
          user.update_attributes({
            :company => company,
            :type => ::User::RIPPLER,
            :state => ::User::ACTIVE
          })
          subscription_user = record.subscription_users.create!({
            :user => user,
            :start_at => DateTime.now,
            :end_at => ::Subscription::FOREVER
          })
        end
      end
      
      # This creates a stripe customer record if none exists
      # or it uses the existing customer record.
      # It creates a new subscription if none exists,
      # or it upgrades the plan on the existing subscription.
      
      def change_stripe_plan(new_plan_name, stripe_token=nil)
        new_plan = Plan.find_by_name(new_plan_name)
        
        if record.has_stripe_record?
          # Upgrade existing customer record
          stripe_customer = Stripe::Customer.retrieve(record.stripe_customer_id)
          stripe_subscription = stripe_customer.subscriptions.retrieve(record.stripe_subscription_id)
          stripe_subscription.plan = new_plan_name
          stripe_subscription.quantity = new_plan.subscription_quantity(record)
          if stripe_token
            # New payment information
            stripe_subscription.source = stripe_token
          end
          stripe_subscription.save
          
          new_subscription = change_plan(new_plan_name, {
            :stripe_token => stripe_token ? stripe_token : record.stripe_token,
            :stripe_customer_id => record.stripe_customer_id,
            :stripe_subscription_id => record.stripe_subscription_id
          })
          return new_subscription
        elsif stripe_token
          # Create new customer record
          stripe_customer = Stripe::Customer.create({
            :source => stripe_token,
            :plan => new_plan.stripe_id,
            :quantity => new_plan.subscription_quantity(record),
            :email => record.owner.email,
            :description => record.company.name,
            :metadata => {
              :company_id => record.company.id,
              :owner_id => record.owner.id,
              :first_name => record.owner.first_name,
              :last_name => record.owner.last_name
            }
          })
          stripe_subscription = stripe_customer.subscriptions.first
          
          new_subscription = change_plan(new_plan_name, {
            :stripe_token => stripe_token,
            :stripe_customer_id => stripe_customer.id,
            :stripe_subscription_id => stripe_subscription.id
          })
          new_subscription.record.subscription_events.create({
            :name => ::SubscriptionEvent::CUSTOMER_CREATED,
            :body => {
              :description => "Created new stripe customer record #{stripe_customer.id}"
            }
          })
          new_subscription.record.subscription_events.create({
            :name => ::SubscriptionEvent::PAYMENT,
            :body => {
              :description => "Initial payment for #{record.plan.name} with stripe token #{stripe_token}"
            }
          })
          return new_subscription
        else
          raise "Can not create a new subscription without a stripe token"
        end
      end
      
      # Upgrades (or downgrades) to a different plan
      # This will cancel the existing subscription,
      # and return a new subscription for the new plan.
      # All existing subscription users will also be copied over to the new plan.
      # If this was the result of a stripe transaction, 
      #  the stripe data passed in new_record_options will be copied on to the new record.
      
      def change_plan(new_plan_name, new_record_options={})
        now = DateTime.now
        new_plan = Plan.find_by_name(new_plan_name)
        record.update_attributes({
          :end_at => now,
          :state => ::Subscription::CANCELED
        })
        new_record = company.subscriptions.create!({
          :company => company,
          :owner => owner,
          :plan => new_plan,
          :start_at => now,
          :end_at => ::Subscription::FOREVER,
          :state => ::Subscription::ACTIVE
        }.merge(new_record_options))
        record.subscription_users.each do |su|
          su.update_attributes({
            :end_at => now
          })
          new_record.subscription_users.create!({
            :user => su.user,
            :start_at => now,
            :end_at => ::Subscription::FOREVER
          })
        end
        
        record.log_event!({
          :name => ::SubscriptionEvent::UPGRADED,
          :body => {
            :description => "Upgraded to #{new_plan_name}"
          }
        })
        new_record.log_event!({
          :name => ::SubscriptionEvent::CREATED,
          :body => {
            :description => "Upgraded from #{record.plan.name}"
          }
        })
        
        return CompanySubscription.new(new_record)
      end
      
      # Use a different card for existing subscription
      
      def change_payment_method(stripe_token)
        if stripe_token.nil? 
          raise 'New stripe token required to update payment method'
        end
        if record.has_stripe_record?
          stripe_customer = Stripe::Customer.retrieve(record.stripe_customer_id)
          stripe_customer.source = stripe_token
          stripe_customer.save
          
          record.log_event!(::SubscriptionEvent::UPDATED, {
            :body => {
              :description => "Updated payment method with token #{stripe_token}"
            }
          })
          
          return self
        else
          raise 'No customer record to update payment method.'
        end
      end
      
      class << self
        
        # This is the main point of entry to create a new company
        # with a subscription, owner, etc. all properly configured.
        # The plan will default to free trial unless specified otherwise.
        
        # @param owner: a user instance, or an email string used to create a new user
        
        def create_subscription(company_name, domain, owner, stub, plan_name=DEFAULT_PLAN)
          if owner.is_a?(String)
            owner = User.create!({
              :email => owner,
              :pending_company_name => company_name,
              :confirmed_at => ::Time.now,
              :password => SecureRandom.password,
              :type => ::User::PROSPECT,
              :state => ::User::INVITED
            })
          end
          
          company = Company.create!({
            :name => company_name,
            :domain => domain,
            :manager => owner,
            :stub => stub
          })
          # don't assume
          # company.use_series(1) # ripple 50 others
          # company.use_series(2) # ripple 50 self
          owner.update_attributes!({
            :company => company,
            :type => ::User::RIPPLER,
            :state => ::User::ACTIVE
          })
          plan = Plan.find_by_name(plan_name)
          subscription = ::Subscription.create!({
            :company => company,
            :owner => owner,
            :start_at => DateTime.now,
            :end_at => ::Subscription::FOREVER,
            :state => ::Subscription::ACTIVE,
            :plan => plan
          })
          subscription.subscription_users.create!({
            :user => owner,
            :start_at => DateTime.now,
            :end_at => ::Subscription::FOREVER
          })
          subscription.log_event!(SubscriptionEvent::CREATED)
          
          return self.new(subscription)
        end
        
      end
    end
  end
end

