require 'test_helper'

class RippleCharacteristicScoreReporterTest < ActiveSupport::TestCase
  describe Ripple::CharacteristicScoreReporter do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(2)
      @user = User.first
      @subject = Ripple::CharacteristicScoreReporter.new(@user)
    end

    describe '#initialize' do
      it 'is initialzied with a user model' do
        assert @subject.user.id == @user.id
      end
    end
    
    describe '#fetch_all_scores' do
      
      def assert_has_characteristic_scores(c)
        assert (c[:characteristic][:name]), 'Missing characteristic name'
        assert (c[:scores][:overall] > 0), 'Missing characteristic score'
      end
      
      def assert_has_zero_characteristic_scores(c)
        assert (c[:characteristic][:name]), 'Missing characteristic name'
        assert (c[:scores][:overall] == 0), 'Missing characteristic score'
      end
      
      def assert_has_histogram_scores(c)
        (0..4).each do |n|
          assert c[:scores][:hist][n][0] == n+1, 'Histogram index is incorrect'
          assert c[:scores][:hist][n][1] != nil, 'Histogram value is missing'
        end
      end
      
      def assert_has_zero_histogram_scores(c)
        (0..4).each do |n|
          assert c[:scores][:hist][n][0] == n+1, 'Histogram index is incorrect'
          assert c[:scores][:hist][n][1] == 0, 'Histogram value is missing'
        end
      end
      
      describe 'with acme company fixtures' do
        before do
          AcmeHelper.generate_acme_plans_and_surveys
          AcmeHelper.generate_acme_responses
          AcmeHelper.generate_acme_scores
          @result = @subject.fetch_all_scores
        end
        
        it 'the first personal score is ripple effect score' do
          assert @result == true, 'Result should be true'
          assert @subject.personal_scores.first[:characteristic][:name] == 'Ripple Effect'
        end
        
        it 'the first company score is ripple effect score' do
          assert @result == true, 'Result should be true'
          assert @subject.company_scores.first[:characteristic][:name] == 'Ripple Effect'
        end
        
        it 'returns personal overall scores for all characteristics' do
          assert @result == true, 'Result should be true'
          assert @subject.personal_scores.length == 6, 'Missing characteristic scores'
          @subject.personal_scores.each do |c|
            assert_has_characteristic_scores(c)
          end
        end
        
        it 'returns company overall scores for all characteristics' do
          assert @result == true, 'Result should be true'
          assert @subject.company_scores.length == 6, 'Missing characteristic scores'
          @subject.company_scores.each do |c|
            assert_has_characteristic_scores(c)
          end
        end
        
        it 'returns a histogram of the responses for all personal characteristics' do
          assert @result == true, 'Result should be true'
          @subject.personal_scores.each do |c|
            assert_has_histogram_scores(c)
          end
        end
        
        it 'returns a histogram of the responses for all company characteristics' do
          assert @result == true, 'Result should be true'
          @subject.company_scores.each do |c|
            assert_has_histogram_scores(c)
          end
        end
      end
      
      describe 'with no scores' do
        before do
          def @subject.has_scores?; false; end
          def @subject.raw_personal_scores; Score.none; end
          def @subject.raw_company_scores; Score.none; end
          @result = @subject.fetch_all_scores
        end
        
        it 'returns false' do
          assert @result == false, 'Result should be false'
        end
        
        it 'assigns 0 for overall scores for all personal characteristics' do
          assert @subject.personal_scores.length == 6, 'Missing characteristic scores'
          @subject.personal_scores.each do |c|
            assert_has_zero_characteristic_scores(c)
          end
        end
        
        it 'assigns 0 for overall scores for all company characteristics' do
          assert @subject.company_scores.length == 6, 'Missing characteristic scores'
          @subject.company_scores.each do |c|
            assert_has_zero_characteristic_scores(c)
          end
        end
      end
      
      describe 'with no scores for some characteristics' do
        before do
          def @subject.has_scores?; true; end
          def @subject.raw_company_scores; Score.none; end
          def @subject.raw_self_scores; Score.none; end
          def @subject.raw_personal_scores
            [
              Score.new({ 
                :characteristic_id => 1, :characteristic => Characteristic.first, 
                :receiver => @user, :company => @user.company,
                :number => 10, :mean => 3, :hist1 => 0.0, :hist2 => 0.0, :hist3 => 1.0, :hist4 => 0.0, :hist5 => 0.0
              }),
              nil, nil, nil, nil, nil
            ]
          end
          @result = @subject.fetch_all_scores
        end
        
        it 'has a score for the one characteristic' do
          assert_has_characteristic_scores(@subject.personal_scores.first)
          assert_has_histogram_scores(@subject.personal_scores.first)
        end
        
        it 'has zero scores for all the other characteristics' do
          (1..5).each do |n|
            assert_has_zero_characteristic_scores(@subject.personal_scores[n])
            assert_has_zero_histogram_scores(@subject.personal_scores[n])
          end
        end
      end
    end
    
  end
end
