require 'test_helper'

class SurveyPlanTest < ActiveSupport::TestCase
  describe 'SurveyPlan' do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(2)
      AcmeHelper.generate_acme_plans # generates self-plan
      Job::CreateCompanySurveys.perform(AcmeHelper.acme_company.id)
    end
    
    subject { SurveyPlan.last }

    describe 'setup' do
      it 'should create four SurveyPlans' do
        assert_equal 4, SurveyPlan.count
      end

      it 'should create two self-plans - one for each user' do
        assert_equal 2, SurveyPlan.for_self.count
        assert_equal 1, User.first.survey_plans.for_self.count
        assert_equal 1, User.last.survey_plans.for_self.count
      end

      it 'should create two other-plans - one for each user' do
        assert_equal 2, SurveyPlan.for_others.count
        assert_equal 1, User.first.survey_plans.for_others.count
        assert_equal 1, User.last.survey_plans.for_others.count
      end
    end

    describe 'associations' do
      it 'has a giver' do
        assert subject.giver.present?, "No giver"
      end

      it 'has a receiver' do
        assert subject.receiver.present?, "No receiver"
      end

      it 'has a company survey series' do
        assert subject.company_survey_series.present?, "No company survey series"
      end

      it 'has many surveys' do
        assert subject.surveys.any?, "No surveys"
      end
    end

    describe 'scopes' do
      describe '#for_pair' do
        it 'does not return false negatives' do
          left_user = User.first
          right_user = User.second
          assert SurveyPlan.for_pair(left_user, right_user).any?, "Should be a survey plan"
          assert SurveyPlan.for_pair(right_user, left_user).any?, "Should be a survey plan"
        end

        it 'does not return false positives' do
          SurveyPlan.destroy_all
          left_user = User.first
          right_user = User.second
          refute SurveyPlan.for_pair(left_user, right_user).any?, "Should be a survey plan"
          refute SurveyPlan.for_pair(right_user, left_user).any?, "Should be a survey plan"
        end
      end

      describe '#for_self' do
        it 'returns the proper scope' do
          assert_equal [User.first.survey_plans.first], User.first.survey_plans.for_self
        end
      end

      describe '#for_others' do
        it 'returns the proper scope' do
          assert_equal [User.first.survey_plans.last], User.first.survey_plans.for_others
        end
      end
    end

    describe '#set_next_due' do
      before { Timecop.freeze(Time.now) }

      it 'sets to now for first survey' do
        Survey.destroy_all
        assert_equal Time.now, subject.send('set_next_due')
      end

      it 'respects :hours_between_surveys' do
        assert_equal subject.company_survey_series.config['hours_between_surveys'],
          (subject.send('set_next_due') - subject.surveys.last.created_at).to_i / 3600
      end

      it 'respects :create_manually' do
        config = {"for_self"=>false, "allow_comments"=>true, "create_manually"=>true}
        subject.company_survey_series.update_attributes(config: config)
        assert_equal Ripple::Time::WHEN_ROBOTS_RULE, subject.send('set_next_due')
      end
    end

    describe '#uniqueness' do
      it 'prevents duplicates' do
        sp = SurveyPlan.last
        refute sp.dup.save, "Should have failed validation"
      end
    end
  end
end
