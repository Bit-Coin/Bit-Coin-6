require 'test_helper'

class AdminReportsTest < Capybara::Rails::TestCase
  before do
    TestHelper.seed_admin
    AcmeHelper.generate_acme_company_data
    login_as Admin.first, scope: :admin
  end

  describe 'admin reports' do
    it 'renders' do
      skip # TODO
    end
  end
end
