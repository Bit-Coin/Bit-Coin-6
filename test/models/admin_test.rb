require 'test_helper'

class AdminTest < ActiveSupport::TestCase
  before do
    Admin.create!(
      email: 'demo+admin@ripplecrew.com',
      password: Security::DEMO_PASSWORD,
      first_name: 'Thor',
      last_name: 'Thegodofthunder'
    )
  end
  
  test 'create' do
    assert Admin.first, 'No admin account'
  end

  # duplicated in user_test.rb
  test 'password validations' do
    u = Admin.first
    u.password = 'bad'
    refute u.valid?
    u.password = 'shoRt1'
    refute u.valid?
    u.password = 'longButNotComplex'
    refute u.valid?
    u.password = 'longAndComplex123'
    assert u.valid?
    u.password = Security::DEMO_PASSWORD
    assert u.valid?
  end
end
