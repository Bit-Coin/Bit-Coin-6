require 'test_helper'

class RespondToSurveysTest < Capybara::Rails::TestCase
  before do
    TestHelper.test_javascript
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    AcmeHelper.generate_acme_plans_and_surveys
  end

  describe 'respond when signed in' do
    before do
      login_as User.first, scope: :user
    end

    it 'allows completion' do
      visit next_survey_path
      assert_content 'you are completing'
      all('.never').each do |b|
        b.click
      end
      assert_selector('.selected', count: 5)
      find_button("big_survey_button").click
      assert page.has_content?('You have no open Ripple Reflection Surveys'), "Finish button didn't work"
    end
  end

  describe 'respond when tokenized' do
    it 'allows completion' do
      visit short_path(short_path: User.first.short_path)
      assert_equal edit_survey_path(User.first.next_survey), current_path
      all('.always').each do |b|
        b.click
      end
      assert_selector('.selected', count: 5)
      find_button("big_survey_button").click
      assert page.has_content?('You have no open Ripple Reflection Surveys'), "Finish button didn't work"
    end
  end

  describe 'leave some comments' do
    it 'allows a single comment' do
      visit short_path(short_path: User.first.short_path)
      assert_equal edit_survey_path(User.first.next_survey), current_path
      all('.always').each do |b|
        b.click
      end
      find("input[name='comments']").click
      fill_in 'comment-0', visible: true, with: Faker::Lorem.sentence
      find_button("big_survey_button").click
      assert page.has_content?('You have no open Ripple Reflection Surveys'), "Finish button didn't work"
    end
  end
end
