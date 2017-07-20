# For various health-status checks

class StatusController < ApplicationController
  skip_before_filter :authenticate_user!, :require_company_context

  def summary
    summary = {
      message: 'A OK',
      timestamp: Time.now
    }
    render json: summary
  end
end
