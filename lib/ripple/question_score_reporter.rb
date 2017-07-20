module Ripple
  
  # This class efficiently marshals out score records 
  # into a format that is easily digestible by views
  
  class QuestionScoreReporter
    
    attr_reader :user, :personal_scores, :company_scores, :self_scores
    
    def initialize(user, parent_characteristic_id=1)
      @user = user
      @personal_scores = []
      @company_scores = []
      @self_scores = []
      @parent_characteristic_id = parent_characteristic_id
    end
    
    def fetch_all_scores
      raw_personal_scores.each do |score|
        @personal_scores[score.question_id] = unpack_score_record(score)
      end
      raw_company_scores.each do |score|
        @company_scores[score.question_id] = unpack_score_record(score)
      end
      raw_self_scores.each do |score|
        @self_scores[score.question_id] = unpack_score_record(score)
      end
      has_scores?
    end
    
    def personal_score_for_question(question)
      @personal_scores[question.id] || blank_score_for_question(question)
    end
    
    def company_score_for_question(question)
      @company_scores[question.id] || blank_score_for_question(question)
    end
    
    def self_score_for_question(question)
      @self_scores[question.id] || blank_score_for_question(question)
    end
    
    def blank_score_for_question(question)
      {
        :question => {
          :id => question.id,
          :text => question.personalized_text_for(user)
        },
        :scores => {
          :overall => 0.0,
          :number => 0,
          :hist => [
            [1, 0.0], [2, 0.0], [3, 0.0], [4, 0.0], [5, 0.0]
          ]
        },
        :comments => []
      }
    end
    
    def unpack_score_record(score)
      {
        :question => {
          :id => score.question.id,
          :text => score.question.personalized_text_for(user)
        },
        :scores => {
          :overall => score.mean.to_f.round(1),
          :number => score.number.to_i,
          :hist => [
            [1, score.hist1.to_f.round(2)], 
            [2, score.hist2.to_f.round(2)], 
            [3, score.hist3.to_f.round(2)], 
            [4, score.hist4.to_f.round(2)], 
            [5, score.hist5.to_f.round(2)]
          ]
        },
        :comments => score.question.comments_for(user)
      }
    end
    
    # Active Record Quarantine Zone

    def component_characteristics
      Characteristic.find(@parent_characteristic_id).components.order(:id)
    end

    def questions
      ccids = component_characteristics.pluck(:id)
      if ccids.any?
        Question.where('characteristic_id in (?)', ccids).order(:characteristic_id)
      else
        Question.where('characteristic_id = ?', @parent_characteristic_id).order(:id)
      end
    end

    def has_scores?
      Score.where(:receiver_id => @user.id).count > 0
    end
    
    # TODO scope raw scores for parent_characteristic

    def raw_personal_scores
      @rps ||= @user.personal_scores.published.for_parent_characteristic(@parent_characteristic_id)
    end
    
    def raw_company_scores
      @rcs ||= @user.company.scores_for_company.published.for_parent_characteristic(@parent_characteristic_id)
    end
    
    def raw_self_scores
      @rss ||= @user.self_scores.published.for_parent_characteristic(@parent_characteristic_id)
    end

    def highest_scores(question)
      @highest_scores = []
      personal_score = personal_score_for_question(question)[:scores][:overall]
      question.characteristic.all_questions.each do |que|
        if personal_score_for_question(que)[:scores][:overall] > personal_score
          @highest_scores << '"'"#{personal_score_for_question(que)[:question][:text]}"'" ' "(#{personal_score_for_question(que)[:scores][:overall]}, vs. #{self_score_for_question(que)[:scores][:overall]} self-score)"
        end
      end
      @highest_scores
    end

    def lower_scores(question)
      @lower_scores = []
      personal_score = personal_score_for_question(question)[:scores][:overall]
      question.characteristic.all_questions.each do |que|
        if personal_score_for_question(que)[:scores][:overall] < personal_score
          @lower_scores << '"'"#{personal_score_for_question(que)[:question][:text]}"'" ' "(#{personal_score_for_question(que)[:scores][:overall]}, vs. #{self_score_for_question(que)[:scores][:overall]} self-score)"
        end
      end
      @lower_scores
    end


  end
end
