module Api
  module V1
    class RegistrationsController < Api::V1::ApplicationController
      skip_before_action :authenticate_user_from_token!
      rescue_from FbGraph2::Exception::InvalidToken, with: :render_unauthorized

      def facebook
        token = request.headers['X-Facebook-Token']
        fail(Errors::NotAuthorized, 'No Facebook token provided') unless token

        fb_user = FbGraph2::User.me(token).fetch
        user = User.new(username: params[:username])
        user.apply_third_party_auth(Fave::Auth.from_facebook(fb_user))

        return sign_in_and_render(user) if user.save

        invalid_user_creation(user)
      end

      private

      def sign_in_and_render(user)
        sign_in user, store: false
        render 'facebook', status: 201
      end

      def invalid_user_creation(user)
        warden.custom_failure!
        render json: { errors: user.errors }, status: 400
      end
    end
  end
end
