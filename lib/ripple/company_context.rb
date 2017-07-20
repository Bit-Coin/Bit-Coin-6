module Ripple
  module CompanyContext
    
    def company=(company)
      Thread.current[:company] = company
    end
    
    def is_set?
      Thread.current[:company].present?
    end
    
    def company
      if is_set?
        Thread.current[:company]
      else 
        raise ContextError.new("No context")
      end
    end
    
    def clear
      Thread.current[:company] = nil
    end
    
    extend self
  end
  
  class ContextError < StandardError
  end
  
end

Ripple::CompanyContext.clear
