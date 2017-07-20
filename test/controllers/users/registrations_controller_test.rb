require 'test_helper'

class Users::RegistrationsControllerTest < ActionController::TestCase

  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    AcmeHelper.generate_acme_subscription
  end

  test 'cannot edit without being authed' do 
    @request.env["devise.mapping"] = Devise.mappings[:user]
    user = User.first
    get :edit, id: user.id
    assert_response 302
  end

  test 'cannot edit someone else' do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    user = User.first
    sign_in user
    refute_equal user.id, User.last.id
    get :edit, id: User.last.id # try to load a different user
    refute_equal User.last, assigns(:user) # shouldn't assign it
    assert_equal user, assigns(:user) # should assign current_user
  end

  test 'can update stuff' do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    user = User.first
    sign_in user
    put :update, user: { mobile_phone: '7815551212', last_name: 'Garp', 
                         hire_date: '2000-01-01', use_sms: 1,
                         current_password: Security::DEMO_PASSWORD }
    user.reload
    assert_equal '+17815551212', user.mobile_phone
    assert_equal 'Garp', user.last_name
    assert_equal Date.parse('2000-01-01'), user.hire_date
    assert_equal '1', user.use_sms
    assert_redirected_to edit_user_registration_path(user)
  end

  test 'create user stub unregistered domain' do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    email = Faker::Internet.email
    post :create_user_stub, user: {
      email: email,
      email_confirmation: email
    }
    assert_equal 'prospect', User.last.type
    assert_equal email, User.last.email
  end

  test 'complete prospect registration unregistered domain' do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    email = Faker::Internet.email
    post :create_user_stub, user: {
      email: email,
      email_confirmation: email
    }
    user = User.find_by_email(email)
    user.confirm!
    post :create_pending_registration, {
      id: user.id,
      first_name: 'Joe',
      last_name: 'Ripple',
      company_account: 1,
      company_name: 'Owelo Inc.'
    }
    user.reload
    assert_equal 'Joe', user.first_name
    assert_equal 'Ripple', user.last_name
    assert_equal 'Owelo Inc.', user.pending_company_name
  end

  test 'register prospect with pilot company' do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    email = 'joe@example.com' # AcmeDemo
    post :create_user_stub, user: {
      email: email,
      email_confirmation: email
    }
    user = User.find_by_email(email)
    user.confirm!
    assert_equal User::RIPPLER, user.type
    assert_equal User::ACTIVE, user.state
    post :create_rippler_registration, {
      id: user.id,
      first_name: 'Joe',
      last_name: 'Ripple',
      password: Security::DEMO_PASSWORD,
      password_confirmation: Security::DEMO_PASSWORD
    }
    user.reload
    assert_equal 'Joe', user.first_name
    assert_equal 'Ripple', user.last_name
    assert_equal 'Acme Demo, Inc.', user.company.name
  end
end
