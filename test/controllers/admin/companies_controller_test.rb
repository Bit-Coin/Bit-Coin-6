require 'test_helper'

class Admin::CompaniesControllerTest < ActionController::TestCase
  tests Admin::CompaniesController
  let(:good_csv) {
    csv = "first_name,last_name,email\n"
    5.times do
      csv += "#{Faker::Name.first_name},#{Faker::Name.last_name},#{Faker::Internet.email}\n"
    end
    csv
  }
  let(:bad_csv) {
    csv = "first_name,last_name,email\n"
    5.times do
      csv += "#{Faker::Name.first_name},#{Faker::Name.last_name},bad-email@notanemail\n"
    end
    csv    
  }

  before do 
    TestHelper.seed_admin
    sign_in Admin.first
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(1) # need a maven
    AcmeHelper.generate_acme_subscription
    @acme = AcmeHelper.acme_company
  end

  describe '#bulk create users to maven' do
    it 'creates users and sends emails' do
      post :bulk_create_users, id: @acme.id, csv: good_csv, connect_maven: 1
      assert_equal "Successfully created 5 new users, with 10 new survey plans",
        flash[:notice]
      assert_equal 5, ActionMailer::Base.deliveries.count, "Missing emails"
      refute flash[:error], "Should not throw flash error"
    end

    it 'does not send email for invalid rows' do
      post :bulk_create_users, id: @acme.id, csv: bad_csv, connect_maven: 1
      assert_equal 1, @acme.members.count # only the maven
      refute ActionMailer::Base.deliveries.any?, "Should not be any mail"
      assert_equal "There were 5 invalid rows. Users were not created.",
        flash[:error]
    end
  end
end
