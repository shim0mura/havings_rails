class UserController < ApplicationController

  before_action :set_user, only: [:index, :timeline, :item_list, :item_tree, :item_images, :favorite_items, :favorite_images, :dump_items, :following, :followers]
  before_action :authenticate_user!, only: [:get_self, :list_tree]

  def get_self
    @user = current_user
    @current_user = user_signed_in? ? current_user : nil
    @home_list = @user.get_home_list
    get_item_images
    @background_image = (@next_images.first.present? ? @next_images.first.image_url : nil)
  end

  def index
    @current_user = user_signed_in? ? current_user : nil
    @home_list = @user.get_home_list

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

  def item_tree
    @relation = (@user == current_user) ? Relation::HIMSELF : Relation::NOTHING
    @item_tree = @user.item_tree(relation_to_owner: @relation).first
  end

  def item_list
    @home_list = @user.get_home_list
    from = params[:from].to_i rescue 0

    get_user_items(from)

    sleep(3)
  end

  def item_images
    page = params[:page].to_i rescue 0
    get_item_images(page)

    sleep(5)
  end

  def favorite_items
    # favorites = @user.his_own_favorite_items(from)
    # @favorite_items = Item.countable
    #   .includes(:user, :tags, :item_images)
    #   .where(id: favorites.map(&:item_id))
    # @has_next_item = @favorite_items.count >= Item::SHOWING_ITEM + 1
    # @last_favorite_id = favorites.last.id rescue 0


    page = params[:page].to_i rescue 0
    # private_typeが公開のものしか取得しない
    # アイテムとそのownerとのrelationをいちいち取得するのが面倒なのと
    # どうせ非公開はowner以外は見れないしわざわざ自分のをお気に入りする
    # 使い方はレアケースじゃないかという理由から
    @favorites = Favorite.joins(:item)
      .where(user_id: @user.id)
      .where("items.private_type <= ?", 0)
      .order("items.id DESC")
      .includes(:item, :user, item:[:item_images, :tags, :favorites])
      .page(page)

    # @favorites = Favorite.joins(item:[:user])
    #   .where("favorites.user_id = ?", @user.id)
    #   .where("items.private_type <= ?", 0)
    #   .order("items.id DESC")
    #   .eager_load(:item, :user, item:[:item_images, :tags, :favorites])
    #   .page(page)

    @has_next_item = !@favorites.last_page?
    @next_page_for_item = @has_next_item ? @favorites.current_page + 1 : nil

  end

  def favorite_images
    page = params[:page].to_i rescue 0

    @image_favorites = ImageFavorite.joins(:item, :item_image)
      .where(user_id: @user.id)
      .where("items.private_type <= ?", 0)
      .order("item_images.added_at DESC")
      .includes(item:[:user], item_image:[:image_favorites])
      .page(page)

    @has_next_image = !@image_favorites.last_page?
    @next_page_for_image = @has_next_image ? @image_favorites.current_page + 1 : nil
    @user_id = current_user.present? ? current_user.id : nil

  end

  def dump_items
    @home_list = @user.get_home_list

    page = params[:page].to_i rescue 0
    relation_to_owner = @user.get_relation_to(current_user)

    @dump_items = Item
      .includes(:item_images, :tags, :favorites)
      .dump
      .where(user_id: @user.id)
      .where("private_type <= ?", relation_to_owner)
      .order("id DESC")
      .page(page)

    @has_next_item = !@dump_items.last_page?
    @next_page_for_item = @has_next_item ? @dump_items.current_page + 1 : nil

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

  # TODO: 削除
  #       まだandroid側が使ってる
  def get_user_items(from = 0)
    @next_items = Item.countable
                    .includes(:tags, :item_images, :favorites)
                    .where(user_id: @user.id)
                    .where("id > ?", from)
    #.limit(Item::SHOWING_ITEM + 1)

    @has_next_item = @next_items.size >= Item::SHOWING_ITEM + 1
  end

  def get_item_images(page = 0)
    relation = (current_user.present? && (@user.id == current_user.id)) ? Relation::HIMSELF : Relation::NOTHING

    @next_images = ItemImage.joins(item:[:user])
      .where("users.id = ?", @user.id)
      .where("items.private_type <= ?", relation)
      .order("item_images.added_at DESC")
      .eager_load(:item, :image_favorites)
      .page(page)

    @has_next_image = !@next_images.last_page?
    @next_page_for_image = @has_next_image ? @next_images.current_page + 1 : nil
  end

  def get_user_item_images_count
    ItemImage.joins(item:[:user]).where("users.id = ?", @user.id).count
  end

end
