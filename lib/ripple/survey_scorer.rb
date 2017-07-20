require_relative './descriptive_statistics_array'

module Ripple
  
  # Creates score records for the given survey responses
  
  class SurveyScorer
     
    attr_reader :receiver, :surveys, :scores
   
    def initialize(receiver, surveys)
      @receiver = receiver
      @surveys = surveys
      @by_character = initialize_characteristic_hash
      @by_question = {}
      @scores = []
    end
  
    def create_scores
      assign_responses
      aggregate_responses_for_characteristics
      aggregate_responses_for_questions
      @scores
    end
  
    def mark_scored
      surveys.update_all(:state => 'scored')
    end
  
    def assign_responses
      surveys.each do |s|
        s.responses.each do |r|
          if r.score
            # assign to characteristic
            if r.characteristic_id
              @by_character[r.characteristic_id] << r.score
            end

            # assign to parent_characteristic if necessary
            if r.characteristic.parent_characteristic_id
              @by_character[r.characteristic.parent_characteristic_id] << r.score
            end

            # assign to question
            if @by_question[r.question_id].nil?
              @by_question[r.question_id] = Ripple::DescriptiveStatisticsArray.new 
            end
            @by_question[r.question_id] << r.score
          end
        end
      end
    end
    
    def aggregate_responses_for_characteristics
      @by_character.each do |characteristic_id, score_array|
        if score_array.length === 0
          score_array << 0 # Your score will be 0, even less than 1; think on this
        end
        score = Score.create!({
          :receiver_id => self.receiver_id,
          :company_id => self.company_id,
          :cohort_name => cohort_name,
          :characteristic_id => characteristic_id,
          :question_id => nil,
          :stats => score_array.survey_statistics,
          :state => 'published',
          :published_at => DateTime.now
        })
        @scores << score
      end
    end
    
    def aggregate_responses_for_questions
      @by_question.each do |question_id, score_array|
        if score_array.length === 0
          score_array << 0
        end
        score = Score.create!({
          :receiver_id => self.receiver_id,
          :company_id => self.company_id,
          :cohort_name => cohort_name,
          :characteristic_id => nil,
          :question_id => question_id,
          :stats => score_array.survey_statistics,
          :state => 'published',
          :published_at => DateTime.now
        })
        @scores << score
      end
    end
    
    # This is trivially extended by UserSurveyScorer, CompanySurveyScorer
    
    def company_id
      raise 'Abstract, extended by customer or user scorer'
    end
    
    def receiver_id
      raise 'Abstract, extended by customer or user scorer'
    end

    def initialize_characteristic_hash
      tmp = {}
      self.company.company_survey_series.active.each do |css|
        pc = css.survey_series.parent_characteristic
        tmp[pc.id] = Ripple::DescriptiveStatisticsArray.new
        pc.components.each do |cc|
          tmp[cc.id] = Ripple::DescriptiveStatisticsArray.new
        end
      end
      tmp
    end
  
  end
end