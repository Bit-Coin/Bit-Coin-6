require 'test_helper'

class RailsAdminTest < Capybara::Rails::TestCase
  test 'must log in' do
    visit '/admin/rails'
    assert page.has_content? 'You need to sign in or sign up before continuing.'
  end
end
