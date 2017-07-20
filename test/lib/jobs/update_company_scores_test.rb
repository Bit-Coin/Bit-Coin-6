require 'test_helper'

class UpdateCompanyScoresTest < ActiveSupport::TestCase
  describe Job::UpdateCompanyScores do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(2)
      AcmeHelper.generate_acme_plans_and_surveys
      AcmeHelper.generate_acme_responses
    end
    
    describe '.perform' do
      let(:company) { AcmeHelper.acme_company }
      
      before do
        Job::UpdateCompanyScores.perform(company.id)
      end
      
      it 'scores the user' do
        assert (company.scores.published.count > 0), "Company does not have scores"
      end
    end
  end
end
