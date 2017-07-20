require 'test_helper'

class InvitationsTest < Capybara::Rails::TestCase
  describe 'managing invitations' do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users
      AcmeHelper.generate_acme_plans_and_surveys    
      login_as User.first, scope: :user    
    end

    it 'lets me invite someone' do
      visit manage_invitations_path
      email = Faker::Internet.email
      fill_in 'giver1', with: email
      click_button "Send Invitation"
      assert_equal manage_invitations_path, current_path
    end
  end
end
