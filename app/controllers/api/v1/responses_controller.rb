class Api::V1::ResponsesController < Api::V1::BaseController
  respond_to :json
  skip_before_action :require_company_context, only: [:survey_response]
  before_action :get_response

  # POST /api/v1/survey_response
  def survey_response
    if @response.update(strong_params)
      render json: @response, status: :ok
    else
      @response.survey.log_event!('response_validation_error', {
          severity: Event::CRITICAL, body: {
            description: "Response #{@response.id} updated on closed survey",
            params: params
          }
        })
      flash[:error] = "There was a problem and your response was not saved. If the " +
        "problem persists, contact support@ripplecrew.com for help."
      render json: 'Cannot update responses on closed surveys',
        status: :internal_server_error
    end
  end

  private

  def strong_params
    params.require(:response).permit(:score)
  end

  def get_response
    Ripple::CompanyContext.company = current_user.company unless 
      Ripple::CompanyContext.is_set?
    @response = current_user.scoped_responses.find(params[:id])
  end
end
