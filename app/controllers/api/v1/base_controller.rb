module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_key!

      private

      def authenticate_api_key!
        authenticate_or_request_with_http_token do |token, _options|
          @current_api_user = User.find_by(api_token: token)
        end
      end

      def current_api_user
        @current_api_user
      end
    end
  end
end
