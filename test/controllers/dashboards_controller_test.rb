require 'test_helper'

class DashboardsControllerTest < ActionController::TestCase

  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(1)
  end

  test 'unauthenticated redirect' do
    get :show
    assert_redirected_to new_user_session_path
  end

  test '200 if authenticated' do
    sign_in User.first
    get :show
    assert_response :ok
  end

  test 'does not accept user token' do
    get :show, user_email: User.first.email, user_token: User.first.authentication_token
    assert_redirected_to new_user_session_path
  end
end
