require 'test_helper'

class RippleIndividualSubscriptionTest < ActiveSupport::TestCase
  describe Ripple::Subscription::IndividualSubscription do
    
    describe '.create_subscription' do
      subject { Ripple::Subscription::IndividualSubscription }
      
      before do
        @subscription = subject.create_subscription('Acme', 'example.com', 'owner@example.com')
      end
      
      it 'creates a user, who is in pending state' do
        user = @subscription.record.owner
        assert user.is_a? User
        assert user.email === 'owner@example.com'
        assert user.type === User::PROSPECT
        assert user.state === 'active'
      end
    end
  end
end

