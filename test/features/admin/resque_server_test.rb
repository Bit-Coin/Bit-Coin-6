require 'test_helper'

class ResqueServerTest < Capybara::Rails::TestCase
  test 'must log in' do
    visit '/admin/resque/overview'
    assert page.has_content? 'You need to sign in or sign up before continuing.'
  end
end
