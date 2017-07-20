require_relative './survey_scorer'

module Ripple
  
  class UserSurveyScorer < Ripple::SurveyScorer
    
    def receiver_id
      @receiver.id
    end
    
    def company_id
      nil
    end
    
    def user
      @receiver
    end
    
    def company
      @receiver.company
    end
    
    def cohort_name
      nil
    end
    
  end
end