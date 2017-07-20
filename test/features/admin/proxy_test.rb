require 'test_helper'

class ProxyTest < Capybara::Rails::TestCase
  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users
    TestHelper.seed_admin
    login_as Admin.first, scope: :admin
  end

  describe 'proxying a rippler' do
    it 'does not barf on company context' do
      visit '/admin'
      find_link("All User Accounts").click
      assert_nothing_raised do
        first(:link, "Proxy").click
      end
      assert_equal Company.first, Ripple::CompanyContext.company
    end
  end
end
