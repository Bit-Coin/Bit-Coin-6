require 'test_helper'

class UpdatePersonalScoresTest < ActiveSupport::TestCase
  describe Job::UpdatePersonalScores do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(2)
      AcmeHelper.generate_acme_plans_and_surveys
      AcmeHelper.generate_acme_responses
    end
    
    describe '.perform' do
      let(:user) { AcmeHelper.acme_company.users.first }
      
      before do
        Job::UpdatePersonalScores.perform(user.id)
      end
      
      it 'scores the user' do
        assert (user.personal_scores.published.count > 0), "User does not have scores"
      end
    end
  end
end
