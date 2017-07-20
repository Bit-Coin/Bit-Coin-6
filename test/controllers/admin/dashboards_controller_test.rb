require 'test_helper'

class Admin::DashboardsControllerTest < ActionController::TestCase

  test 'unauthenticated redirect' do
    get :show
    assert_redirected_to new_admin_session_path
  end
end
