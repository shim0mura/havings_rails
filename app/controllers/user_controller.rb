class UserController < ApplicationController

  before_action :set_user, only: [:index, :timeline, :item_list, :item_images, :favorite_items, :favorite_images, :dump_items, :following, :followers]
  before_action :authenticate_user!, only: [:list_tree]

  def index
    @current_user = user_signed_in? ? current_user : nil
    @home_list = @user.get_home_list

    get_user_items

    get_item_images

    @user_item_image_count = get_user_item_images_count
    @background_image = (@next_images.first.present? ? @next_images.first.image_url : nil)

    @user_timeline = @user.timeline(current_user)
    @has_next_event = @user.has_next_event_from?(@user_timeline.last[:event_id])
  end

  def timeline
    timeline = @user.timeline(current_user, params[:from])
    render partial: 'shared/timeline', layout: false, locals: {timeline: timeline, has_next_event: @user.has_next_event_from?(timeline.last[:event_id])}
  end

  def list_tree
  end

  def item_list
    @home_list = @user.get_home_list
    from = params[:from].to_i rescue 0

    get_user_items(from)

    sleep(3)
  end

  def item_images
    from = params[:from].to_i rescue 0
    get_item_images(from)

    sleep(5)
  end

  def favorite_items
    from = params[:from].to_i rescue 0
    favorites = @user.his_own_favorite_items(from)
    @favorite_items = Item.countable
      .includes(:user, :tags, :item_images)
      .where(id: favorites.map(&:item_id))
    @has_next_item = @favorite_items.count >= Item::SHOWING_ITEM + 1
    @last_favorite_id = favorites.last.id rescue 0
  end

  def favorite_images
    from = params[:from].to_i rescue 0
    favorites = @user.his_own_favorite_images(from)
    @favorite_images = ItemImage
      .includes(:image_favorites, item:[:user])
      .where(id: favorites.map(&:item_image_id))
    @has_next_image = @favorite_images.count >= ItemImage::MAX_SHOWING_USER_ITEM_IMAGES + 1
    @last_favorite_id = favorites.last.id rescue 0
    @user_id = current_user.present? ? current_user.id : nil
  end

  def dump_items
    @home_list = @user.get_home_list
    from = params[:from].to_i rescue 0

    @dump_items = Item.dump_items(@user, current_user, from)
    @has_next_item = @dump_items.count >= Item::SHOWING_ITEM + 1

    @dump_items = []
    @has_next_item = false

  end

  def following
    @users = get_users(@user.following, current_user)
    @heading_text = "フォローしているユーザー"
  end

  def followers
    @users = get_users(@user.followed, current_user)
    @heading_text = "フォロワー"
    render 'following'
  end

  private
  def set_user
    @user = User.find(params[:user_id])
  end

  def get_users(users, current_user)
    users.map do |user|
      home_list = user.get_home_list
      light_user = user.to_light
      light_user[:total_item_count] = home_list.count
      light_user[:relation] = user.get_relation_to(current_user)
      if current_user
        # light_user[:is_following] = current_user.already_follow?(user.id)
        light_user[:is_following_viewer] = user.already_follow?(current_user.id)
      else
        light_user[:is_following_viewer] = false
      end
      light_user
    end
  end

  def get_user_items(from = 0)
    @next_items = Item.countable
                    .includes(:tags, :item_images, :favorites)
                    .where(user_id: @user.id)
                    .where("id > ?", from)
                    .limit(Item::SHOWING_ITEM + 1)

    @has_next_item = @next_items.size >= Item::SHOWING_ITEM + 1
  end

  def get_item_images(from = 0)
    if from != 0
      from_option = ItemImage.arel_table[:id].lt(from)
      i = ItemImage.where(from_option)
    else 
      i = ItemImage
    end
    @next_images = i.joins(item:[:user]).where("users.id = ?", @user.id).order("item_images.added_at DESC").limit(ItemImage::MAX_SHOWING_USER_ITEM_IMAGES + 1).eager_load(:item, :image_favorites)

    @has_next_image = @next_images.size >= ItemImage::MAX_SHOWING_USER_ITEM_IMAGES + 1
  end

  def get_user_item_images_count
    ItemImage.joins(item:[:user]).where("users.id = ?", @user.id).count
  end

end
