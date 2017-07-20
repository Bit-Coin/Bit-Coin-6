class Api::V1::BaseController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  skip_before_filter :authenticate_user! # required for token auth (not in AppController)
  acts_as_token_authentication_handler_for User
  before_filter :authenticate_user!

  def render_404
    render json: 'not found', status: 404
  end
end
