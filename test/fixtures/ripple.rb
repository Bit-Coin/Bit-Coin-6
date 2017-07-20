class RippleHelper
  class << self

    def seed
      require_relative '../fixture_scripts/ripple_analytics.rb'
    end

    def create_ripple_company
      Company.create(name: 'Ripple Analytics Inc.', domain: 'ripplecrew.com', stub: 'ripple')
    end
  end
end
