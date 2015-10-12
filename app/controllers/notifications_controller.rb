class NotificationsController < ApplicationController

  before_action :authenticate_user!

  def read
    if current_user.notification.read
      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end
  end

end
