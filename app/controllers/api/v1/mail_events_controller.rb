class Api::V1::MailEventsController < ActionController::Base
  force_ssl if Rails.env.production?
  before_filter :authenticate_source!

  API_KEY = '49b9c7f697e9fb3f4b04'
  API_SECRET = 'b0351de802b50c628772f48f5f0a8f0c'

  # POST /api/v1/mail_event?api_key=key&api_secret=secret&_json=json
  def mail_event
    Resque.enqueue(Job::ParseEmailEvents, params['_json'])
    render json: 'Message received.', status: 200
  end

  private

  def authenticate_source!
    unless params[:api_key] == API_KEY && params[:api_secret] == API_SECRET
      render json: 'Invalid API authentication.', status: 400 # bad request
    end
  end
end
