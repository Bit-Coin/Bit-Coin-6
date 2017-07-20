require 'test_helper'

class SubscriptionEventTest < ActiveSupport::TestCase

  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users
    AcmeHelper.generate_acme_subscription    
  end

  subject { Subscription.first }

  it 'creates' do
    subject.log_event!('test')
    assert subject.subscription_events.any?
  end

end
