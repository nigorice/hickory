module A
  module V1
    class ProfileController < A::V1::ApplicationController
      respond_to :json

      def index
      end

      def update
        render 'index'
      end
    end
  end
end
