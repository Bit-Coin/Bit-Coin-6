require 'test_helper'

class Users::ConfirmationsControllerTest < ActionController::TestCase

  before do
    @prospect = TestHelper.seed_prospect
    @prospect.update_attributes!(confirmed_at: nil)
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test 'get the form' do
    get :new
    refute Ripple::CompanyContext.is_set?
  end

  test 'sends confirmation instructions to prospect' do
    user = User.prospect.first
    refute Ripple::CompanyContext.is_set?, "Should not have company context"
    post :create, user: { email: user.email }
    assert_equal [user.email], ActionMailer::Base.deliveries.first.to
  end
end
