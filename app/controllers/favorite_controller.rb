class FavoriteController < ApplicationController

  before_action :authenticate_user!, only: [:create, :destroy]
  before_action :set_item, only: [:create, :destroy]

  def index
  end

  def create
    unless @item.can_show?(current_user)
      render json: { }, status: :unprocessable_entity
    end

    favorite = Favorite.new(
      user_id: current_user.id,
      item_id: @item.id
    )

    if favorite.save

      event = Event.create(
        event_type: :favorite,
        acter_id: current_user.id,
        suffered_user_id: @item.user_id,
        related_id: @item.id,
        properties: {
          favorite_id: favorite.id
        }
      )
      @item.user.notification.add_unread_event(event)

      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end

  end

  def destroy
    favorite = Favorite.where(
      user_id: current_user.id,
      item_id: @item.id
    ).first.destroy

    if favorite.destroyed?
      Event.where(
        event_type: Event.event_types["favorite"],
        acter_id: current_user.id,
        suffered_user_id: @item.user_id,
        related_id: @item.id
      ).update_all(is_deleted: true)

      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end
  end

  private
  def set_item
    @item = Item.find(params[:id])
  end

end
