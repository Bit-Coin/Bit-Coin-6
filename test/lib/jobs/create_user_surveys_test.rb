require 'test_helper'

class Job::CreateUserSurveysTest < ActiveSupport::TestCase
  describe Job::CreateUserSurveys do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(2)
      AcmeHelper.generate_acme_plans
      AcmeHelper.generate_acme_surveys
    end
    
    describe '.perform' do
      let(:user) { AcmeHelper.acme_company.users.first }
      let(:survey_plan) { user.giver_survey_plans.for_others.first }
      let(:self_plan) { user.giver_survey_plans.for_self.first }
      
      describe 'with open surveys' do
        it 'does not create new surveys' do
          existing_survey = user.surveys.first
          Job::CreateUserSurveys.perform(user.id)
          assert existing_survey.state === 'open', 'Existing survey was modified'
        end
      end
      
      describe 'with completed surveys, but no plans due' do
        it 'does not create new surveys' do
          AcmeHelper.generate_acme_responses
          existing_survey_count = user.surveys.count
          Job::CreateUserSurveys.perform(user.id)
          assert existing_survey_count === user.surveys.count, 'New surveys were created'
        end
      end
      
      describe 'with completed surveys, and self/other plans due' do
        it 'creates new surveys' do
          AcmeHelper.generate_acme_responses
          assert survey_plan.surveys.open.count === 0, 'Complete all surveys first'
          refute survey_plan.due? || self_plan.due?, "Should not be due"
          survey_plan.update_attributes!(:next_due => Time.now)
          self_plan.update_attributes!(:next_due => Time.now)
          assert survey_plan.reload.due? && self_plan.reload.due?, "Should be due"
          Job::CreateUserSurveys.perform(user.id)
          assert user.reload.surveys.open.count == 2, 'Not all surveys were created'
        end
      end
    end
  end
end

