class FollowsController < ApplicationController

  before_action :authenticate_user!, only: [:create, :destroy]

  def index
  end

  def create

    if current_user.id == params[:user_id].to_i || !user_exist?(params[:user_id].to_i)
      render json: { }, status: :unprocessable_entity
      return
    end

    if current_user.already_follow?(params[:user_id].to_i)
      render json: { }, status: :unprocessable_entity
      return
    end

    follow = Follow.new(
      following_user_id: current_user.id,
      followed_user_id:  params[:user_id]
    )

    if follow.save
      event = Event.create(
        event_type: :follow,
        acter_id: current_user.id,
        suffered_user_id: follow.followed_user_id,
      )
      @followed_user.notification.add_unread_event(event)

      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end

  end

  def destroy
    unless user_exist?(params[:user_id].to_i) && current_user.already_follow?(params[:user_id].to_i)
      render json: { }, status: :unprocessable_entity
      return
    end

    follow = Follow.where(
      following_user_id: current_user.id,
      followed_user_id:  params[:user_id]
    ).first.destroy


    if follow.destroyed?
      @followed_user
      Event.where(
        event_type: Event.event_types["follow"],
        acter_id: current_user.id,
        suffered_user_id: follow.followed_user_id
      ).update_all(is_deleted: true)

      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end
  end

  private
  def user_exist?(user_id)
    @followed_user = User.where(id: user_id).first
  end

end
