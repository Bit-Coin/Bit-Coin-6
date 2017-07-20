module Api
  module V1
    class WidgetsController < ApplicationController
      respond_to :json

      # GET /api/v1/widgets
      def widgets
        render json: Characteristic.pluck(:name)
      end

    end
  end
end
