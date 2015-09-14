class UserController < ApplicationController

  # before_action :authenticate_user!, only:[:follow, :remove]

  def index
    @user = User.find(params[:user_id])
    @current_user = user_signed_in? ? current_user : nil
  end

end
