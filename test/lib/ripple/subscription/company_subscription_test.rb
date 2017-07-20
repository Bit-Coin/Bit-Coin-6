require 'test_helper'

class RippleCompanySubscriptionTest < ActiveSupport::TestCase
  describe Ripple::Subscription::CompanySubscription do

    describe '#register_user' do
      subject do
        Ripple::Subscription::CompanySubscription.create_subscription('Acme', 'example.com', 'owner@example.com', 'acme')
      end
      
      let(:email) { 'oh+ho@example.com' }
     
      before do
        @user = User.create!({
          :email => email,
          :password => SecureRandom.password,
          :company => subject.company,
          :type => User::UNREGISTERED_GIVER,
          :state => 'invited'
        })
        @su = subject.register_user(@user)
      end
      
      it 'updates the user to an active rippler' do
        assert @su.is_a? SubscriptionUser
        assert @su.user.company == subject.company, 'User is not assigned to the company'
        assert @su.user.type == User::RIPPLER
        assert @su.user.state == 'active'
      end
      
      it 'creates a subscription user record' do
        assert @su.user_id == @user.id
        assert @su.subscription_id == subject.record.id
        assert @su.start_at < DateTime.now
        assert @su.end_at === Subscription::FOREVER
      end
    end
    
    describe '#change_plan' do
      subject do
        Ripple::Subscription::CompanySubscription.create_subscription('Acme', 'example.com', 'owner@example.com', 'acme', 'free_trial_1')
      end
      
      let(:new_plan_name) { 'company_1' }
      
      before do
        @new_subscription = subject.change_plan(new_plan_name)
      end
      
      it 'cancels the existing subscription' do
        assert subject.record.state == Subscription::CANCELED
        assert subject.record.end_at != Subscription::FOREVER
      end
      
      it 'marks the subscription user records ended' do
        assert subject.record.subscription_users.first.end_at != Subscription::FOREVER
      end
      
      it 'creates a new subscription with the given plan' do
        assert @new_subscription.is_a? Ripple::Subscription::CompanySubscription
        assert @new_subscription.record != subject.record
        assert @new_subscription.record.state === Subscription::ACTIVE  
        assert @new_subscription.record.plan.name === new_plan_name
        assert @new_subscription.record.company_id == subject.record.company_id
        assert @new_subscription.record.owner_id === subject.record.owner_id
      end
      
      it 'creates new subscription user records' do
        su = @new_subscription.record.subscription_users.first
        assert su.is_a? SubscriptionUser
        assert su.user_id === subject.record.subscription_users.first.user_id
        assert su.end_at === Subscription::FOREVER
      end
    end
    
    describe '#change_stripe_plan' do
      subject do
        Ripple::Subscription::CompanySubscription.create_subscription('Acme', 'example.com', 'owner@example.com', 'acme', 'free_trial_1')
      end
      
      let(:new_plan_name) { 'company_1' }
      let(:stripe_token) { 'tok_15sIYcAJkB8dJrsDtXJK111Z' }
      
      before do
        response = File.read(File.join(Rails.root, 'test/fixtures/stripe_response_new_customer.json'))
        stub_request(:post, /api\.stripe\.com/).to_return(:status => 200, :body => response, :headers => {})
        @new_subscription = subject.change_stripe_plan(new_plan_name, stripe_token)
      end
      
      it 'cancels the existing subscription' do
        assert subject.record.state == Subscription::CANCELED
        assert subject.record.end_at != Subscription::FOREVER
      end
      
      it 'creates a new subscription with the given plan' do
        assert @new_subscription.is_a? Ripple::Subscription::CompanySubscription
        assert @new_subscription.record != subject.record
        assert @new_subscription.record.state === Subscription::ACTIVE  
        assert @new_subscription.record.plan.name === new_plan_name
        assert @new_subscription.record.company_id == subject.record.company_id
        assert @new_subscription.record.owner_id === subject.record.owner_id
        assert @new_subscription.record.stripe_token.present?
        assert @new_subscription.record.stripe_customer_id.present?
        assert @new_subscription.record.stripe_subscription_id.present?
      end
    end
    
    describe '#change_payment_method' do
      subject do
        Ripple::Subscription::CompanySubscription.create_subscription('Acme', 'example.com', 'owner@example.com', 'acme', 'company_1')
      end
      
      let(:stripe_token) { 'tok_15sIYcAJkB8dJrsDtXJK111Z' }
      
      before do
        subject.record.update_attributes({
          :stripe_customer_id => 'cus_65sJWAifKqNnhS',
          :stripe_subscription_id => 'sub_65sJapzV7S7MAX',
        })
        response = File.read(File.join(Rails.root, 'test/fixtures/stripe_response_new_customer.json'))
        stub_request(:get, /api\.stripe\.com/).to_return(:status => 200, :body => response, :headers => {})
        stub_request(:post, /api\.stripe\.com/).to_return(:status => 200, :body => response, :headers => {})
      end
      
      it 'updates the customer record, and returns self' do
        subscription = subject.change_payment_method(stripe_token)
        assert subscription.is_a? Ripple::Subscription::CompanySubscription
      end
      
      it 'creates a new subscription event for the update' do
        subscription = subject.change_payment_method(stripe_token)
        event = subscription.record.subscription_events.last
        assert event.name === SubscriptionEvent::UPDATED
      end
    end
    
    describe '.create_subscription' do
      subject { Ripple::Subscription::CompanySubscription }
      
      let(:owner) {
        Ripple::OnboardUser.create_prospect('Joe', 'Duck', 'jd@example.com', 'Duckies Inc')
      }
      
      before do
        @subscription = subject.create_subscription('Acme', 'example.com', owner, 'acme')
      end
      
      it 'creates a new company record' do
        company = @subscription.company
        assert company.is_a? Company
        assert company.name === 'Acme'
        assert company.domain === 'example.com'
      end
      
      it 'creates a new subscription object with a record, including stripe transaction info' do
        assert @subscription.is_a? Ripple::Subscription::CompanySubscription
        assert @subscription.record.is_a? Subscription
        assert @subscription.record.start_at < DateTime.now
        assert @subscription.record.end_at === Subscription::FOREVER
        assert @subscription.record.state === Subscription::ACTIVE
      end
      
      it 'uses the default plan for the new subscription' do
        assert @subscription.record.plan.is_a? Plan
        assert @subscription.record.plan.name === Ripple::Subscription::CompanySubscription::DEFAULT_PLAN
      end
      
      it 'assigns the user, as both the company manager and subscription owner' do
        assert_equal @subscription.record.owner, owner
        assert_equal @subscription.record.company.manager, owner
      end
    end
  end
end

