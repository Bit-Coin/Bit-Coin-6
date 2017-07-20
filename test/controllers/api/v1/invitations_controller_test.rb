require 'test_helper'

class Api::V1::InvitationsControllerTest < ActionController::TestCase

  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    RippleHelper.create_ripple_company
  end

  test 'creates an unregistered giver' do
    sign_in User.first
    email = Faker::Internet.email
    assert_equal [], ActionMailer::Base.deliveries
    post :create, email: email
    user = User.find_by_email(email)
    assert user
    assert_equal 'unregistered_giver', user.type
    assert_equal 'invited', user.state
    assert_match /I recently signed up for Ripple/, 
      ActionMailer::Base.deliveries.last.body.parts.last.body.raw_source
  end

  test 'invite an already unregistered_giver' do
    
    unregistered_giver = AcmeHelper.generate_acme_user_of_type('unregistered_giver')
    
    sign_in User.first
    email = User.unregistered_givers.first.email
    assert_equal [], ActionMailer::Base.deliveries
    post :create, email: email
    assert_response :success
    user = User.find_by_email(email)
    assert user
    assert_equal 'unregistered_giver', user.type
    assert_equal 'active', user.state
    assert_match /I recently signed up for Ripple/, 
      ActionMailer::Base.deliveries.last.body.parts.last.body.raw_source
  end

  test 'invite someone already in another company' do 
    sign_in User.first
    other_user = User.offset(1).first
    ripple = Company.find_by_domain('ripplecrew.com')
    other_user.update_attributes({
      :company_id => ripple.id
    })
    email = other_user.email
    post :create, email: email
    assert_response :error
  end

  test 'cannot invite yourself' do 
    sign_in User.first
    email = User.first.email
    post :create, email: email
    assert_response :error
    assert_match /You cannot invite yourself./, response.body
  end 

  test 'cannot invite someone more than once' do 
    AcmeHelper.generate_acme_plans
    
    sign_in User.first
    email = User.first.survey_plans.for_others.first.giver.email
    post :create, email: email
    assert_response :error
    assert_match /is already in your Ripplecrew/, response.body
  end

  test 'cannot invite bounced email' do
    user = User.rippler.sample
    email = Faker::Internet.email

    sp = user.survey_plans.build_from_params(receiver: user, email: email, state: 'active')
    sp.save!
    assert sp.state == 'active', "Should be active"

    sp.giver.bounce!
    assert sp.giver.state == 'bouncing'
    
    sign_in user
    post :create, email: email

    assert_response :error
    assert_match /Please delete and enter a new email address./, response.body
  end

  test 'cannot invite unsubscribed' do
    user = User.rippler.sample
    email = Faker::Internet.email

    sp = user.survey_plans.build_from_params(receiver: user, email: email, state: 'active')
    sp.save!
    assert sp.state == 'active'

    sp.giver.unsubscribe!
    assert sp.giver.state == 'unsubscribed'

    sign_in user
    post :create, email: email
    assert_response :error
    assert_match /has asked not to participate./, response.body
  end

  test 'delete plan' do
    AcmeHelper.generate_acme_plans_and_surveys
    sp = SurveyPlan.last
    assert_equal 'active', sp.state
    sign_in sp.receiver
    delete :destroy, id: sp.id
    sp.reload
    assert_equal 'deleted', sp.state
    refute sp.surveys.open.any?, "Should not have open surveys"
  end

  test '#resend!' do
    AcmeHelper.generate_acme_plans_and_surveys
    sp = SurveyPlan.last
    assert sp.resend!, "Should return true"
  end
end
