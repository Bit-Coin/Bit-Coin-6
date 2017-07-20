require_relative './survey_scorer'

module Ripple
  
  class CompanySurveyScorer < Ripple::SurveyScorer
    
    def receiver_id
      nil
    end
    
    def company_id
      @receiver.id
    end
    
    def user
      nil
    end
    
    def company
      @receiver
    end
    
    def cohort_name
      'company'
    end
  end
end