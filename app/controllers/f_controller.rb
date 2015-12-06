class FController < ApplicationController
  before_action :authenticate_user!

  def index
    FaveWorker.perform_async(
      current_user.id.to_s,
      params[:url],
      Time.zone.now.to_s,
      params[:title],
      params[:image_url],
      params[:published_at]
      )

    render layout: false
  end
end
