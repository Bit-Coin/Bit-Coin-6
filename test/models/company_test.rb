require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  before do
    @acme = AcmeHelper.generate_acme_company
  end

  describe '#use_series' do
    it 'does not allow duplicate survey series' do
      assert @acme.company_survey_series.pluck(:survey_series_id).include?(1)
      assert_raises(ActiveRecord::RecordInvalid) { @acme.use_series(1, {allow_comments: true}) }
    end
  end

  describe 'feedback scopes' do
    before do
      AcmeHelper.generate_acme_users(4)
      AcmeHelper.generate_acme_subscription
      AcmeHelper.generate_acme_plans
      AcmeHelper.generate_acme_surveys
      AcmeHelper.generate_acme_comments
      AcmeHelper.generate_acme_responses
    end

    it 'includes self-surveys' do
      assert @acme.feedback.for_self.any?, "Self surveys should be included in company feedback"
      assert @acme.feedback.for_others.for_self.blank?, "Can't have self surveys in feedback.for_others"
    end
  end
end
