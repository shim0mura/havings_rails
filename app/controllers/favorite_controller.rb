class FavoriteController < ApplicationController

  before_action :authenticate_user!, only: [:create, :destroy, :image_favorite, :image_unfavorite]
  before_action :set_item, only: [:create, :destroy, :favorited_users]
  before_action :set_item_image, only: [:image_favorite, :image_unfavorite, :image_favorited_users]

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

    begin
      ActiveRecord::Base.transaction do
        favorite.save!

        event = Event.create!(
          event_type: :favorite,
          acter_id: current_user.id,
          suffered_user_id: @item.user_id,
          related_id: @item.id,
          properties: {
            favorite_id: favorite.id
          }
        )
        @item.user.notification.add_unread_event(event)
      end

      render json: { status: :ok }
    rescue => e
      logger.error("favorite_item_failed, item_id: #{@item.id}, user_id: #{current_user.id}, #{e}, #{e.backtrace}")
      render json: { }, status: 500
    end

  end

  def destroy
    begin
      ActiveRecord::Base.transaction do
        favorite = Favorite.where(
          user_id: current_user.id,
          item_id: @item.id
        ).first.destroy
        if favorite.destroyed?
          result = Event.where(
            event_type: Event.event_types[Event::FAVORITE],
            acter_id: current_user.id,
            suffered_user_id: @item.user_id,
            related_id: @item.id
          ).update_all(is_deleted: true)
          raise if result <= 0
        else
          raise
        end
      end

      render json: { status: :ok }
    rescue => e
      logger.error("un_favorite_item_failed, item_id: #{@item.id}, user_id: #{current_user.id}, #{e}, #{e.backtrace}")
      render json: {}, status: 500
    end
  end

  def favorited_users
    favorited_user_ids = @item.favorites.map(&:user_id)
    @users = User.where(id: favorited_user_ids)
  end

  def image_favorite
    @item = @item_image.item
    if !@item.present?
      render json: { errors: {image_not_found: ["."]} }, status: :unprocessable_entity
    end

    image_favorite = ImageFavorite.new(
      user_id:       current_user.id,
      item_id:       @item.id,
      item_image_id: @item_image.id
    )

    pp image_favorite

    begin
      ActiveRecord::Base.transaction do
        image_favorite.save!

        event = Event.create!(
          event_type: :image_favorite,
          acter_id: current_user.id,
          suffered_user_id: @item.user_id,
          related_id: @item_image.id,
          properties: {
            image_favorite_id: image_favorite.id,
            item_id: @item.id
          }
        )
        @item.user.notification.add_unread_event(event)
      end

      render json: { status: :ok }
    rescue => e
      logger.error("favorite_item_image_failed, item_id: #{@item_image.id}, user_id: #{current_user.id}, #{e}, #{e.backtrace}")
      render json: { }, status: 500
    end
  end

  def image_unfavorite
    @item = @item_image.item

    unless @item.present?
      render json: { errors: {image_not_found: ["."]} }, status: :unprocessable_entity
    end

    begin
      ActiveRecord::Base.transaction do

        image_favorite = ImageFavorite.where(
          user_id: current_user.id,
          item_image_id: @item_image.id
        ).first.destroy

        if image_favorite.destroyed?
          result = Event.where(
            event_type: Event.event_types[Event::IMAGE_FAVORITE],
            acter_id: current_user.id,
            suffered_user_id: @item.user_id,
            related_id: @item_image.id
          ).update_all(is_deleted: true)
          raise if result <= 0

        else
          raise
        end

      end
      render json: { status: :ok }
    rescue => e
      logger.error("unfavorite_item_image_failed, item_id: #{@item_image.id}, user_id: #{current_user.id}, #{e}, #{e.backtrace}")
      render json: { }, status: 500
    end

  end

  def image_favorited_users
    image_favorited_user_ids = @item_image.image_favorites.map(&:user_id)
    @users = User.where(id: image_favorited_user_ids)
    render action: :favorited_users
  end

  private
  def set_item
    @item = Item.find(params[:id])
  end

  def set_item_image
    @item_image = ItemImage.find(params[:image_id])
  end

end
