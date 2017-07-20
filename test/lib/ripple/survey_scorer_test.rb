require 'test_helper'

def create_survey
  Survey.new.tap do |s|
    (2..6).each do |i|
      s.responses.build({
        :characteristic_id => i,
        :question_id => i,
        :score => rand(5) + 1
      })
    end
  end
end

class RippleSurveyScorerTest < ActiveSupport::TestCase
  
  describe Ripple::SurveyScorer do
    before do
      AcmeHelper.generate_acme_company
      AcmeHelper.generate_acme_users(2)
      @user = User.first
    end
    
    describe '#create_scores' do
      describe 'with no surveys' do
        before do
          @subject = Ripple::UserSurveyScorer.new(@user, [])
          @result = @subject.create_scores
        end
        
        it 'generates six new zero score records for the user' do
          assert @result.length == 6, 'Missing score records'
          @result.each_with_index do |score, i|
            assert score.receiver_id == @user.id, 'Score receiver_id is incorrect'
            assert score.state == 'published', 'Score state is not published'
            assert score.stats["number"].to_i == 1, 'The stats num is not 1'
            assert score.stats["mean"].to_f == 0.0, 'The stats mean is not 0'
            (1..5).each do |n|
              assert score.stats["hist#{n}"].to_f == 0.0, 'The stats histogram is not 0'
            end
          end
        end
      end
      
      describe 'with a complete set of surveys' do
        before do
          AcmeHelper.generate_acme_plans_and_surveys
          AcmeHelper.generate_acme_responses
          
          @num_surveys = 5
          @surveys = (1..@num_surveys).map { create_survey } # set of five surveys with random scores
          @subject = Ripple::UserSurveyScorer.new(@user, @surveys)
          @result = @subject.create_scores
          @characteristic_scores = @result.select{|s| s.characteristic_id.present? }
          @question_scores = @result.select{|s| s.question_id.present? }
        end
        
        it 'generates six new characteristic score records for the user' do
          assert @characteristic_scores.length == 6, 'Missing characteristic score records'
          @characteristic_scores.each_with_index do |score, i|
            assert score.receiver_id == @user.id, 'Score receiver_id is incorrect'
            assert score.state == 'published', 'Score state is not published'
            assert score.stats["mean"].to_f > 0, 'The stats mean is not gt 0'
            (1..5).each do |n|
              assert score.stats["hist#{n}"].present?, 'The stats histogram is not present'
            end
          end
        end
        
        it 'counts the number of responses scored for each characteristic' do
          @characteristic_scores.each_with_index do |score, i|
            if (score.characteristic_id == 1)
              assert score.stats["number"].to_i == 25, 'The RES stats number is not the correct number of surveys'
            else
              assert score.stats["number"].to_i == 5, 'The characteristic stats number is not the correct number of surveys'
            end
          end
        end
        
        it 'calculates the mean of the responses for each characteristic' do
          @characteristic_scores.each_with_index do |score, i|
            assert score.stats["mean"].present?, 'The stats mean is not present'
            assert score.stats["mean"].to_f > 0, 'The stats mean is not gt 0'
          end
        end
        
        it 'calculates the histogram of the response distribution for each characteristic' do
          @characteristic_scores.each_with_index do |score, i|
            (1..5).each do |n|
              assert score.stats["hist#{n}"].present?, 'The stats histogram is not present'
            end
          end
        end
        
        it 'generates a new score record for every question' do
          assert @question_scores.length == 5, 'Missing question score records'
          @question_scores.each_with_index do |score, i|
            assert score.receiver_id == @user.id, 'Score receiver_id is incorrect'
            assert score.question_id.present?, 'Score question id is not present'
            assert score.state == 'published', 'Score state is not published'
            assert score.stats["mean"].to_f > 0, 'The stats mean is not gt 0'
            (1..5).each do |n|
              assert score.stats["hist#{n}"].present?, 'The stats histogram is not present'
            end
          end
        end
      end

    end
  end
end