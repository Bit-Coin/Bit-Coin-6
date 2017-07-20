module Ripple
  module Subscription
    
    class IndividualSubscription < BaseSubscription
      
      # Individual subscriptions are not yet implemented
      # You can not add additional users to an individual sub at this time
      
      def register_user(email)
        raise 'Unimplemented'
      end
      
      class << self
        
        # Eventually, this will create trial subscriptions for new users.
        # For now, this *does not* create a company/subscription,
        # but only a pending user record
        
        def create_subscription(company_name, domain, email, plan_id=1)
          owner = User.create!({
            email: email, 
            unconfirmed_email: email, 
            password: SecureRandom.password,
            type: User::PROSPECT,
            state: 'active',
            pending_company_name: company_name
          })
          subscription = ::Subscription.new({
            owner: owner
          })
          
          return self.new(subscription)
        end
        
      end
    end
  end
end

