class DeviceTokensController < ApplicationController
  before_action :authenticate_user!

  def create
    # type 0 : android
    #      1 : iOS
    type = params[:type].to_i
    @device_token = DeviceToken.new(token_params)
    @device_token.user_id = current_user.id
    @device_token.device_type = type

    begin
      ActiveRecord::Base.transaction do
        @device_token.save!
      end

      render json: @device_token

    rescue => e

      logger.error("device_token_create_failed, user_id: #{current_user.id}, #{e}, #{e.backtrace}")
      render json: { }, status: 500
    end
  end

  def update
    type = params[:type].to_i

    @device_token = DeviceToken.where(device_type: type, user_id: current_user.id).first

    begin
      ActiveRecord::Base.transaction do
        @device_token.update!(token_params)
      end

      render json: @device_token

    rescue => e

      logger.error("device_token_update_failed, user_id: #{current_user.id}, token_id: #{@device_token.id} #{e}, #{e.backtrace}")
      render json: { }, status: 500
    end

  end

  def change_state
    type = params[:type].to_i
    value = (params[:value].to_i == 1) ? true : false
    @device_token = DeviceToken.where(device_type: type, user_id: current_user.id).first

    begin
      ActiveRecord::Base.transaction do
        @device_token.update_attributes!(is_enable: value)
      end

      render json: @device_token

    rescue => e

      logger.error("device_token_change_failed, user_id: #{current_user.id}, token_id: #{@device_token.id} #{e}, #{e.backtrace}")
      render json: { }, status: 500
    end
  end

  private
  def token_params
    params.require(:device_token).permit(:token)
  end

end
