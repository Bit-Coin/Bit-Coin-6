module Ripple
  module Subscription
    
    class BaseSubscription
      
      attr_reader :record
      
      def initialize(record)
        @record = record || throw('Subscription model record is required')
      end
      
      def company
        record.company
      end
      
      def owner
        record.owner
      end
    end
  end
end

