require 'test_helper'

class LoginTest < Capybara::Rails::TestCase
  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(1)
    AcmeHelper.generate_acme_unregistered_givers
    TestHelper.seed_prospect
    # Ripple::CompanyContext.company = AcmeHelper.acme_company
  end

  it 'works if you know the password' do
    visit login_path
    screenshot_and_save_page
    fill_in 'Email', with: User.first.email
    fill_in 'Password', with: Security::DEMO_PASSWORD
    click_button 'Sign In'
    assert_equal manage_invitations_path, current_path
  end

  it 'logs a system event for bad emails' do
    visit login_path
    fill_in 'Email', with: 'noone@nowhere.com'
    fill_in 'Password', with: 'some_random_password'
    click_button 'Sign In'
    assert_equal '/users/sign_in', current_path
    assert page.has_content? "Invalid"
    assert_equal 'bad_email', SystemEvent.last.name
  end

  it 'does not work with a bad password' do
    visit login_path
    fill_in 'Email', with: User.first.email
    fill_in 'Password', with: 'some_random_password'
    click_button 'Sign In'
    assert_equal '/users/sign_in', current_path
    assert page.has_content? "Invalid"
    assert_equal 'bad_password', UserEvent.last.name
    assert_equal User.first.id, UserEvent.last.eventable_id
  end

  it 'does not allow a prospect to log in' do
    visit login_path
    p = User.prospect.first
    p.confirm!
    p.update_attributes(encrypted_password: Security::ENCRYPTED_DEMO_PASSWORD)
    fill_in 'Email', with: p.email
    fill_in 'Password', with: Security::DEMO_PASSWORD
    click_button 'Sign In'
    assert_equal '/users/sign_in', current_path
    assert page.has_content? "Invalid email or password."
  end

  describe '#forgot_subdomain' do
    it 'does not require context' do
      assert_nothing_raised { visit forgot_login_domain_path }
      refute Ripple::CompanyContext.is_set?, "Should not be a context"
    end
  end
end
