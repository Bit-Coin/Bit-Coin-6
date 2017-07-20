require 'test_helper'

# This tests across self/other/company scores

class Job::UpdateScoresTest < ActiveSupport::TestCase
  describe Job::UpdateScores do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(5)
      AcmeHelper.generate_many_to_one_graph
      AcmeHelper.generate_acme_surveys
      AcmeHelper.generate_acme_responses
    end

    let(:user) { AcmeHelper.acme_company.users.first }
    
    describe 'for a single-receiver company' do      
      before do
        Job::UpdatePersonalScores.perform(user.id)
        Job::UpdateSelfScores.perform(user.id)
        Job::UpdateCompanyScores.perform(user.company.id)
      end

      it 'calculates company scores' do
        assert (user.company.scores_for_company.published.count > 0), "Where are the company scores?"
      end

      it 'calculates personal scores' do
        assert (user.personal_scores.published.count > 0), "No personal scores"
      end

      it 'only has one receiver in the company' do
        assert Survey.all.pluck(:receiver_id).uniq.count == 1, "Should only be one receiver"
      end

      it 'scopes company and personal surveys identically' do
        user_feedback = user.others_feedback.current.scorable
        company_feedback = user.company.feedback.scorable.current
        assert_equal user_feedback.count, company_feedback.for_others.count
      end

      it 'matches company and personal characteristic scores for a single receiver' do
        company_characteristic_scores = user.company.scores_for_company.published.characteristic_scores
        personal_characteristic_scores = user.personal_scores.published.characteristic_scores
        company_characteristic_scores.each do |ccs|
          assert_equal ccs.stats['mean'].to_f, 
            personal_characteristic_scores.where('characteristic_id = ?', ccs.characteristic_id)
              .first.stats['mean'].to_f
        end
      end
    end
  end
end
