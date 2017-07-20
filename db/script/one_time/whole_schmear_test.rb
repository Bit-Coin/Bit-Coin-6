require 'test_helper'

class WholeSchmearTest < ActiveSupport::TestCase

  describe 'Testing whole schmear' do
    describe 'migrations' do
      it 'populates survey_series' do
        assert_equal 5, SurveySeries.count
        assert_equal 1, SurveySeries.for_self.count
      end

      it 'creates CompanySurveySeries' do
        Company.all.each do |c|
          assert c.company_survey_series.active.count > 0, 
            "#{c.name} lacks any active CompanySurveySeries"
        end
      end
    end

    describe 'fannie mae' do
      load 'db/script/one_time/set_up_fannie_mae.rb'
      @@fannie = Company.where(domain: 'fanniemae.com').first

      it 'created the company' do
        assert @@fannie, "No company"
      end

      it 'created the EAL characteristic' do
        assert_equal 8, Characteristic.where(name: 'effective_admired_leader_score').first.id
      end

      it 'created the EAL survey series, set, and questions' do
        eal_ss = SurveySeries.where(name: 'EAL/20-up').first
        assert_equal 5, eal_ss.id
        assert_equal 1, eal_ss.survey_sets.count
        assert_equal 20, eal_ss.survey_sets.first.questions.count
        assert_equal 5, SurveySeries.count
      end

      it 'faked up some data' do
        assert Ripple::CharacteristicScoreReporter.new(User.find_by_email('lisa@listenlearnleadllc.com')).has_scores?,
          "No scores for Lisa"
      end
    end

    describe 'question import' do
      it 'populates survey_series_id correctly' do
        TestHelper.seed_custom_questions
        assert_equal 14, SurveySet.count
        refute SurveySet.where('survey_series_id is null').any?, "Null survey_sets.survey_series_id"
        SurveySeries.all.each do |ss|
          assert ss.survey_sets.any?, "No survey set"
        end
      end
    end
  end
end
