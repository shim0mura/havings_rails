class FavoriteController < ApplicationController

  before_action :authenticate_user!, only: [:create, :destroy]

  def index
  end

  def create
    favorite = Favorite.new(
      user_id: current_user.id,
      item_id: params[:id]
    )

    if favorite.save
      item = Item.find(params[:id])
      event = Event.create(
        event_type: :favorite,
        acter_id: current_user.id,
        suffered_user_id: item.user_id,
        related_id: item.id,
        properties: {
          favorite_id: favorite.id
        }
      )
      item.user.notification.add_unread_event(event)

      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end

  end

  def destroy
    favorite = Favorite.where(
      user_id: current_user.id,
      item_id: params[:id]
    ).first.destroy

    if favorite.destroyed?
      item = Item.find(params[:id])
      Event.where(
        event_type: Event.event_types["favorite"],
        acter_id: current_user.id,
        suffered_user_id: item.user_id,
        related_id: item.id
      ).update_all(is_deleted: true)

      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end
  end

end
