require 'test_helper'

class ShortPathsControllerTest < ActionController::TestCase

  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(1)
  end

  test 'redirect to expanded path with active short path' do
    user = User.first
    get :redirect_to_expanded_path, short_path: user.short_path
    assert Ripple::CompanyContext.is_set?, "Context should be set"
    assert_redirected_to next_survey_url(user_email: user.email,
        user_token: user.authentication_token, host: user.company.host)
    user.reload
    assert_equal 'sign_in', user.events.last.name
    assert_equal user.company, Ripple::CompanyContext.company
  end

  test 'not found error with bad short path' do
    assert_raise ActionController::RoutingError do
      get :redirect_to_expanded_path, short_path: 'thisshouldnotworkinanyway'
    end
    refute Ripple::CompanyContext.is_set?, "Context should not be set"
    assert_equal 'missing_short_path', SystemEvent.last.name
  end

  test 'logged out rippler with old path gets login prompt' do
    user = User.rippler.first
    get :redirect_to_expanded_path, short_path: user.short_paths.order(created_at: :desc).last.path
    assert_redirected_to login_url(host: user.company.host)
    refute Ripple::CompanyContext.is_set?, "Context should not be set"
    assert_equal 'expired_short_path', user.events.last.name
  end

  test 'second-oldest path works too' do
    user = User.rippler.first
    get :redirect_to_expanded_path, short_path: user.short_paths.order(created_at: :desc).second.path
    assert Ripple::CompanyContext.is_set?, "Context should be set"
    assert_redirected_to next_survey_url(user_email: user.email,
        user_token: user.authentication_token, host: user.company.host)
    assert_equal 'sign_in', user.events.last.name
  end

  test "previously authed rippler doesn't need short path" do
    user = User.rippler.first
    sign_in user
    get :redirect_to_expanded_path, short_path: user.short_paths.order(created_at: :desc).last.path
    assert_redirected_to next_survey_url(user_email: user.email,
        user_token: user.authentication_token, host: user.company.host)
    assert_equal 'sign_in', user.events.last.name
  end

  test 'u_g with old path is allowed to continue' do
    AcmeHelper.generate_acme_unregistered_givers
    user = User.unregistered_givers.first
    3.times { user.set_short_path }
    user.short_paths.first.update_attributes(created_at: Time.now - 57.days)
    user.short_paths.last.update_attributes(created_at: Time.now - 29.days)
    get :redirect_to_expanded_path, short_path: user.short_paths.order(created_at: :desc).last.path
    assert Ripple::CompanyContext.is_set?, "Context should be set"
    assert_redirected_to next_survey_url(user_email: user.email,
        user_token: user.authentication_token, host: user.company.host)
    assert_equal 'ug_short_path', user.events.last.name
  end

  test 'admin login does not throw system event' do
    TestHelper.seed_admin
    sign_in Admin.first
    refute Ripple::CompanyContext.is_set?, "Context should not be set"
    refute SystemEvent.any?
  end
end
