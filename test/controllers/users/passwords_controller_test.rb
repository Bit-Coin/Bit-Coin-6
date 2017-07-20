require 'test_helper'

class Users::PasswordsControllerTest < ActionController::TestCase

  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(1)
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test 'getting the form' do
    assert_nothing_raised Ripple::ContextError do
      get :new
    end
    refute Ripple::CompanyContext.is_set?, "Should not need a context"
  end

  test 'reset defaults to user with highest id' do
    orig_user, dup_user = AcmeHelper.duplicate_acme_user_in_ripple_company
    post :create, user: { email: orig_user.email }
    refute orig_user.reload.reset_password_token, "Wrong user"
    assert dup_user.reload.reset_password_token, "No reset token"
  end

  test 'sends reset instructions to rippler' do
    user = User.rippler.first
    post :create, user: { email: user.email }
    refute Ripple::CompanyContext.is_set?, "Does not require company context"
    assert_equal [user.email], ActionMailer::Base.deliveries.first.to
  end

  test 'does not send password reset for prospects' do
    prospect = TestHelper.seed_prospect
    prospect.confirm!
    ActionMailer::Base.deliveries.clear # email confirmation message
    post :create, user: { email: prospect.email }
    refute ActionMailer::Base.deliveries.any?
    refute Ripple::CompanyContext.is_set?
  end

  test 'does not send password reset for UGs' do
    AcmeHelper.generate_acme_unregistered_givers
    ActionMailer::Base.deliveries.clear
    ug = User.unregistered_givers.first
    post :create, user: { email: ug.email }
    refute ug.reset_password_token, "Should not set password reset token"
    refute ug.reset_password_sent_at, "Should not send password reset token"
    refute ActionMailer::Base.deliveries.any?
    refute Ripple::CompanyContext.is_set?
  end

  test 'sets company context correctly' do
    user = User.rippler.active.first
    token = user.send('set_reset_password_token')
    response = post :update, user: {reset_password_token: token, 
      password: 'bLarp$456', password_confirmation: 'bLarp$456'}
    assert user.reload.valid_password?('bLarp$456'), "#{assigns['user'].errors.messages.to_s}"
    assert Ripple::CompanyContext.is_set?, "No context"
    assert_redirected_to dashboard_path
  end
end
