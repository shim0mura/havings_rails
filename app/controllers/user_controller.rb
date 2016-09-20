class UserController < ApplicationController

  # before_action :authenticate_user!, only:[:timeline, :list_tree, :user_items, :item_tree, :classed_items]
  before_action :authenticate_user!, only:[:timeline, :list_tree, :item_tree, :classed_items]
  before_action :set_user, only: [:index, :timeline, :user_items, :item_tree, :item_images, :favorite_items, :favorite_images, :dump_items, :following, :followers]

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
    @relation = (@user == current_user) ? Relation::HIMSELF : Relation::NOTHING

    get_user_items
    get_item_images

    @user_item_image_count = get_user_item_images_count
    @background_image = (@next_images.first.present? ? @next_images.first.image_url : nil)

    # @user_timeline = @user.timeline(@current_user)
    # @has_next_event = @user.has_next_event_from?(@user_timeline.last[:event_id])
    gon.item = @home_list.showing_events
    
  end

  def timeline
    timeline = @user.timeline(current_user, params[:from])
    render partial: 'shared/timeline', layout: false, locals: {timeline: timeline, has_next_event: @user.has_next_event_from?(timeline.last[:event_id])}
  end

  def list_tree
  end

  def item_tree
    include_dump_value = params[:include_dump].to_i rescue 0
    include_dump = (include_dump_value == 1) ? true : false
    @relation = (@user == current_user) ? Relation::HIMSELF : Relation::NOTHING
    @item_tree = @user.item_tree(relation_to_owner: @relation, include_dump: include_dump).first
  end

  # def item_list
  #   @home_list = @user.get_home_list
  #   from = params[:from].to_i rescue 0

  #   get_user_items(from)
  # end

  # 自分のタグ分類されたアイテムを表示
  # 今のところ自分のモノしか見れないように
  def classed_items
    @home_list = current_user.get_home_list
    page = params[:page].to_i rescue 0
    tag_id = params[:tag_id].to_i rescue 0
    # relation_to_owner = @user.get_relation_to(current_user)
    relation_to_owner = Relation::HIMSELF

    tag = ActsAsTaggableOn::Tag.where(id: tag_id).first
    tag_ids = []
    if tag.present?
      related_tags = ActsAsTaggableOn::Tag.where(parent_id: tag.id) if tag.present?
      tag_ids.push(tag.id)
      tag_ids.concat(related_tags.map(&:id))
    end

    @classed_item = Item
      .includes(:item_images, :tags, :favorites)
      .where(
        user_id: current_user.id,
        classed_tag_id: tag_ids,
        is_list: false
      )
      .where("private_type <= ?", relation_to_owner)
      .order("id DESC")
      .page(page)

    @has_next_item = !@classed_item.last_page?
    @next_page_for_item = @has_next_item ? @classed_item.current_page + 1 : nil
  end


  def user_items
    page = params[:page].to_i rescue 0
    get_user_items(page)
  end

  def item_images
    page = params[:page].to_i rescue 0
    get_item_images(page)
  end

  def favorite_items
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
    @popular_list = Item.get_popular_list
    @heading_text = "フォローしているユーザー"
  end

  def followers
    @users = get_users(@user.followed, current_user)
    @heading_text = "フォロワー"
    @popular_list = Item.get_popular_list
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

  def get_user_items(page = 0)
    relation = (current_user.present? && (@user.id == current_user.id)) ? Relation::HIMSELF : Relation::NOTHING

    @next_items = Item.countable
      .includes(:tags, :item_images, :favorites)
      .where(user_id: @user.id)
      .where("private_type <= ?", relation)
      .page(page)
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
