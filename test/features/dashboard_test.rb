require 'test_helper'

class DashboardTest < Capybara::Rails::TestCase
  before do
    TestHelper.test_javascript
  end

  describe 'Ripple Effect dashboard' do
    before do
      AcmeHelper.generate_acme_company_data
      login_as Comment.general.first.receiver, scope: :user
    end

    it 'renders' do
      visit dashboard_path
      assert_content 'Ripple Effect Score'
    end

    it 'displays question level scores' do
      # Demo comments are created in generate_acme_company_data
      visit dashboard_questions_path(cm_id: 1)
      find('#scope-filter').find(:xpath, 'option[2]').select_option
      assert_content "General Comments"
    end
  end

  describe 'EAL dashboard' do
    before do
      load 'db/script/one_time/set_up_fannie_mae.rb'
      lisa = User.find_by_email('lisa@listenlearnleadllc.com')
      login_as lisa, scope: :user
    end

    it 'renders' do
      visit dashboard_path
      assert_content "Effective, Admired Leader Score"
    end
  end
end
