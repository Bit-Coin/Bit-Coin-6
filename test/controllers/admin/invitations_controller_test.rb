require 'test_helper'

class Admin::InvitationsControllerTest < ActionController::TestCase

  before do
    TestHelper.seed_admin
    
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    AcmeHelper.generate_acme_plans_and_surveys
  end
  
  test 'resend' do
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in :admin, Admin.first
    
    sp = SurveyPlan.all.sample
    sp.update_attributes(state: 'notified', created_at: 4.days.ago.to_time)
    
    get :resend, id: sp.id
    assert_match /has been resent/, flash[:notice]
    assert_match /Looking for feedback/, ActionMailer::Base.deliveries.last.subject
  end
  
end
