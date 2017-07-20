require 'test_helper'

class Admin::PromoteProspectsTest < Capybara::Rails::TestCase
  before do
    TestHelper.seed_admin
    @prospect = TestHelper.seed_prospect
    load 'test/fixture_scripts/ripple_analytics.rb'
    login_as Admin.first, scope: :admin
  end

  describe 'promoting prospects' do
    it 'promotes to test driver' do
      visit prospects_admin_users_path
      assert page.has_content?('Ogdred Weary')
      find_link('Test Drive').click
      assert page.has_content?('Test Drive for Ogdred Weary')
      find_button('Start Test Drive').click
      assert page.has_content?('Ogdred Weary is now test driving as part of Ripple Analytics Inc.!')
    end

    it 'promotes to maven' do
      visit prospects_admin_users_path
      find_link("Maven").click
    end
  end
end
