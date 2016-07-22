class FollowsController < ApplicationController

  before_action :authenticate_user!, only: [:create, :destroy]

  def index
  end

  def create

    if current_user.id == params[:user_id].to_i || !user_exist?(params[:user_id].to_i)
      render json: { errors: {user_not_found: ["."]} }, status: :unprocessable_entity
      return
    end

    if current_user.already_follow?(params[:user_id].to_i)
      render json: { errors: {already_following: ["."]} }, status: :unprocessable_entity
      return
    end

    follow = Follow.new(
      following_user_id: current_user.id,
      followed_user_id:  params[:user_id]
    )

    begin
      ActiveRecord::Base.transaction do
        follow.save!
        event = Event.create!(
          event_type: :follow,
          acter_id: current_user.id,
          suffered_user_id: follow.followed_user_id,
        )
        @followed_user.notification.add_unread_event(event)
      end

      render json: { status: :ok }
    rescue => e
      logger.error("follow_failed, following_user_id: #{current_user.id}, target_user_id: #{@user.id}, #{e}, #{e.backtrace}")
      render json: { }, status: 500
    end

  end

  def destroy
    unless user_exist?(params[:user_id].to_i) && current_user.already_follow?(params[:user_id].to_i)
      render json: { errors: {user_not_found: ["."]} }, status: :unprocessable_entity
      return
    end

    begin
      ActiveRecord::Base.transaction do

        follow = Follow.where(
          following_user_id: current_user.id,
          followed_user_id:  params[:user_id]
        ).first.destroy

        if follow.destroyed?
          result = Event.where(
            event_type: Event.event_types["follow"],
            acter_id: current_user.id,
            suffered_user_id: follow.followed_user_id
          ).update_all(is_deleted: true)

          raise if result <= 0

        else
          raise
        end
      end

      render json: { status: :ok }
    rescue => e
      logger.error("unfollow_failed, following_user_id: #{current_user.id}, target_user_id: #{@user.id}, #{e}, #{e.backtrace}")
      render json: { }, status: 500
      render json: { }, status: :unprocessable_entity
    end
  end

  private
  def user_exist?(user_id)
    @followed_user = User.where(id: user_id).first
  end

end
