require 'test_helper'

class UpdateSelfScoresTest < ActiveSupport::TestCase
  describe Job::UpdateSelfScores do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(2)
      AcmeHelper.generate_acme_plans
      AcmeHelper.generate_acme_surveys
      AcmeHelper.generate_acme_responses
    end
    
    describe '.perform' do
      let(:user) { AcmeHelper.acme_company.users.first }
      
      before do
        Job::UpdateSelfScores.perform(user.id)
      end
      
      it 'scores the user' do
        assert (user.self_scores.published.count > 0), "User does not have self scores"
      end
    end
  end
end
