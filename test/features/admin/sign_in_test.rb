require 'test_helper'

class SignInTest < Capybara::Rails::TestCase
  before do 
    TestHelper.seed_admin
  end

  describe 'sign in' do
    it 'does not barf on company context' do
      visit '/admins/sign_in'
      fill_in "Email", with: Admin.first.email
      fill_in "Password", with: Security::DEMO_PASSWORD
      assert_nothing_raised Ripple::ContextError do
        find_button("Sign In").click
      end
      refute Ripple::CompanyContext.is_set?, "CompanyContext should not be set"
    end
  end
end
