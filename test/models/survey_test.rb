require 'test_helper'

class SurveyTest < ActiveSupport::TestCase
  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    AcmeHelper.generate_acme_plans_and_surveys
  end

  describe '#create with a pre-existing open survey' do
    it 'voids the duplicate survey' do
      original = Survey.open.first
      original.giver.surveys.create!({
        receiver: original.receiver, 
        survey_plan: original.survey_plan, 
        survey_set: original.survey_set,
        parent_characteristic_id: original.parent_characteristic_id
      })
      assert original.giver.surveys.open \
              .where('receiver_id = ?', original.receiver_id).count == 0,
              'Did not void duplicate after create'
      assert original.giver.surveys.pending \
              .where('receiver_id = ?', original.receiver_id).count == 1,
              'Did not create pending survey'
    end
  end

  describe '#complete!' do
    it 'returns true' do
      survey = Survey.first
      survey.responses.set_random_scores
      assert Survey.first.complete!, "Should return true"
    end
  end

  describe '#config' do
    it 'returns company survey series config' do
      survey = Survey.first
      assert_equal survey.survey_plan.company_survey_series.config, survey.config
    end
  end
end
