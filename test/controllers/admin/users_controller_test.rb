require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase
  tests Admin::UsersController
  before do
    load 'test/fixture_scripts/ripple_analytics.rb'
    TestHelper.seed_admin
    @prospect = TestHelper.seed_prospect
    sign_in Admin.first
  end

  describe 'promoting prospects' do
    it 'promotes to test driver' do
      post :connect_test_driver, id: @prospect.id
      assert @prospect.reload.rippler?, "Did not promote to test driver"
    end

    it 'promotes to maven' do
      post :create_company, id: @prospect.id, name: 'Fake Company', domain: 'fakecompany.com', stub: 'fake'
      assert_equal 'fake', @prospect.reload.company.stub, "Did not promote to maven"
      assert_equal 2, @prospect.company.company_survey_series.count
    end
  end
end
