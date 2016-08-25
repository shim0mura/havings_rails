# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(190)      default(""), not null
#  encrypted_password     :string(190)      default(""), not null
#  reset_password_token   :string(190)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  token                  :string(190)      not null
#  uid                    :string(160)      not null
#  provider               :string(30)       not null
#  name                   :string(255)
#  image                  :string(255)
#  description            :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class User < ActiveRecord::Base

  MAX_SHOWING_EVENTS = 20

  mount_uploader :image, AvatarUploader

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable,
         :omniauth_providers => [:twitter, :instagram],
         :authentication_keys => [:email]

  before_create :generate_token
  before_create :set_email_provider
  after_create  :create_notification
  after_create  :create_chart
  after_create  :create_home_list

  validates:token, uniqueness: true

  validates :name, presence: true

  # validates_uniqueness_of :email, allow_blank: false, if: :email_need_validate?

  has_many :social_profiles, dependent: :destroy

  has_many :items

  has_many :comments

  has_one :notification
  has_one :chart

  scope :countable, -> { where(is_garbage: false) }

  has_many :favorites
  has_many :image_favorites

  has_many :follows_from, class_name: Follow, foreign_key: :followed_user_id, dependent: :destroy
  has_many :follows_to,   class_name: Follow, foreign_key: :following_user_id,   dependent: :destroy
  has_many :followed,  through: :follows_from,   source: :following_user
  has_many :following, through: :follows_to, source: :followed_user

  # oauth用
  attr_accessor :create_with_oauth

  # 認証トークンが無い場合は作成
  def ensure_token
    generate_token unless self.token
  end

  # 認証トークンの作成
  def generate_token
    loop do
      old_token = self.token
      token = SecureRandom.urlsafe_base64(24).tr('lIO0', 'sxyz')
      if old_token != token
        self.token = token
        return
      end
    end
  end

  def delete_token
    self.update(token: nil)
  end

  def set_email_provider
    if !self.provider.present? && !self.uid.present?
      self.provider = :email
      self.uid = self.email
    end
  end

  def self.first_or_create_with_oauth(social_profile)
    user = social_profile.user
    unless user
      user = new(
        create_with_oauth: true,
        provider: social_profile.provider,
        uid: social_profile.uid,
        name: social_profile.name,
        image: social_profile.image_url,
        description: social_profile.description
      )
      user.save!
    end
    user
  end

  def email_need_validate?
    if create_with_oauth
      return false
    elsif email_changed?
      return true
    elsif persisted?
      return false
    else
      return true
    end
  end

  def email_required?
    if create_with_oauth || provider != "email"
      return false
    else 
      return true
    end
  end

  def password_required?
    return false if create_with_oauth || provider != "email"
    super
  end

  def already_follow?(user_id)
    self.following.map(&:id).include?(user_id.to_i)
  end

  def get_home_list
    Item.includes(child_items:[:tags, :favorites, :item_images]).where(
      user_id: self.id,
      list_id: nil
    ).first
  end

  def create_home_list
    home_list = Item.create(
      name: "ホーム",
      is_list: true,
      is_garbage: false,
      count: 0,
      user_id: self.id,
      list_id: nil,
      private_type: 0
    )
    new_list_event = Event.create(
      event_type: :create_list,
      acter_id: self.id,
      related_id: home_list.id,
      properties: {
        item_id: home_list.id,
        is_home: true
      }
    )
    home_list.change_count(0, new_list_event, home_list)
  end

  def thumbnail
    # TODO:social_profileの画像をどうにかしてuserカラムの中に収めたい
    #      その分sqlを1本減らしたい
    if self.image.present? && image.file.exists?
      image.thumb.url
    elsif social_profiles.present?
      social_profiles.last.image_url
    else
      nil
    end
  end

  def to_light
    {
      id:    self.id,
      name:  self.name,
      image: self.thumbnail,
      description: self.description,
      path:  Rails.application.routes.url_helpers.user_page_path(self.id)
    }
  end

  # def his_own_favorite_items(from = 0)
  #   if from != 0
  #     from_option = Favorite.arel_table[:id].lt(from)
  #   else 
  #     from_option = nil
  #   end
  #   self.favorites.where(from_option).limit(Item::SHOWING_ITEM + 1).order("id DESC")
  # end

  # def his_own_favorite_images(from = 0)
  #   if from != 0
  #     from_option = ImageFavorite.arel_table[:id].lt(from)
  #   else 
  #     from_option = nil
  #   end
  #   self.image_favorites.where(from_option).limit(ItemImage::MAX_SHOWING_USER_ITEM_IMAGES + 1).order("id DESC")
  # end

  def item_tree(current: nil, start_at: nil, items: nil, queue: nil, result: nil, relation_to_owner: nil, include_dump: false)

    if relation_to_owner.nil?
      relation_to_owner = Relation::NOTHING
    end

    if start_at
      queue = Item.where(id: start_at).to_a
    end

    if items.nil?
      if include_dump
        items = Item
          .includes(:item_images, :tags, :favorites)
          .where(user_id: self.id)
          .where("private_type <= ?", relation_to_owner).to_a
      else
        items = Item.countable
          .includes(:item_images, :tags, :favorites)
          .where(user_id: self.id)
          .where("private_type <= ?", relation_to_owner).to_a
      end
    end

    if queue.nil?
      queue = []
      items.delete_if do |item|
        if item.list_id == nil
          queue << item
          true
        end
      end
    end

    current_result = []
    while !queue.empty?
      parent_item = queue.shift
      child_queue = []
      # hash = {
      #   item: parent_item.to_light,
      #   owning_items: nil,
      #   current: (parent_item.id == current),
      #   count: parent_item.count
      # }
      hash = {
        owning_items: nil,
        current: (parent_item.id == current)
      }
      hash.merge!(parent_item.to_light)
      hash[:description] = parent_item.description
      hash[:tags] = parent_item.tags.map{|t|t.name}
      hash[:favorite_count] = parent_item.favorites.size
      items.delete_if do |item|
        if item.list_id == parent_item.id
          child_queue << item
          true
        end
      end
      hash[:owning_items] = item_tree(current: current, start_at: nil, items: items, queue: child_queue, result: Marshal.load(Marshal.dump(result)), relation_to_owner: relation_to_owner, include_dump: include_dump)
      children_count = hash[:owning_items].inject(0){|sum, item| sum + item[:count]} || 0
      # if hash[:item][:is_list]
      if hash[:is_list]
        hash[:count] = children_count
      else
        hash[:count] = hash[:count] + children_count
      end

      current_result << hash
    end
    current_result
  end

  def list_tree(tree = nil, result = [], nest = 0)
    tree = self.item_tree(relation_to_owner: Relation::HIMSELF) unless tree.present? 
    current_result = []
    tree.each do |i|
      if i[:is_list]
        hash = {}
        # hash[:id]    = i[:item][:id]
        hash[:id]    = i[:id]
        # hash[:name]  = i[:item][:name]
        hash[:name]  = i[:name]
        hash[:count] = i[:count]

        hash[:private_type] = i[:private_type]

        hash[:nest]  = nest
        current_result << hash if i[:is_list]
      end
      if i[:owning_items].present?
        current_result.concat(list_tree(i[:owning_items], Marshal.load(Marshal.dump(result)), nest + 1))
      end
    end
    current_result
  end

  def timeline(showing_user = nil, from = 0, limit = MAX_SHOWING_EVENTS)
    # TODO: get_showing_notificationと同じような構造なので
    # 同じにできないか？
    # TODO: add_imageはthumbnailを渡す
    pp limit
    events = get_related_event(from, limit)
    item_ids = []
    followed_user_ids = []
    events.each do |e|
      case(e.event_type)
      when "create_list", "create_item", "image_favorite"
        next unless e.properties
        item_ids << eval(e.properties)[:item_id]
      when "add_image", "dump", "favorite", "comment"
        item_ids << e.related_id
      when "follow"
        followed_user_ids << e.suffered_user_id
      end
    end
    items = Item.where(id: item_ids)
    followed_users = User.where(id: followed_user_ids)

    events.map do |e|
      hash = {
        event_id: e.id,
        type: e.event_type.to_sym,
        acter: [self.to_light],
        target: [],
        date: e.updated_at
      }

      case(e.event_type)
      when "create_list", "create_item"
        item_id = eval(e.properties)[:item_id]
        item = items.detect{|i|i.id == item_id}
        next unless item.present?
        next unless item.can_show?(showing_user)
        hash[:target] << item.to_light
      when "dump", "favorite", "comment"
        item_id = e.related_id
        item = items.detect{|i|i.id == item_id}
        next unless item.present?
        next unless item.can_show?(showing_user)
        hash[:target] << item.to_light
      when "add_image"
        item_id = e.related_id
        item = items.detect{|i|i.id == item_id}
        next unless item.present?
        next unless item.can_show?(showing_user)
        item_images = ItemImage.where(id: eval(e.properties)[:item_image_id])
        # light_item_image = item_images.first.to_light if item_images.present?
        if item_images.present?
          light_item_image = item_images.first.to_light
        else
          next
        end
        hash[:target] << light_item_image
      when "image_favorite"
        item_id = eval(e.properties)[:item_id]
        item = items.detect{|i|i.id == item_id}
        next unless item.present?
        next unless item.can_show?(showing_user)
        item_images = ItemImage.where(id: e.related_id)
        # light_item[:image] = item_images.first.image_url if item_images.present?
        if item_images.present?
          light_item_image = item_images.first.to_light
        else
          next
        end
        hash[:target] << light_item_image
      when "follow"
        followed_user_id = e.suffered_user_id
        user = followed_users.detect{|i|i.id == followed_user_id}
        next unless user.present?
        hash[:target] << user.to_light
      end

      hash
    end.compact
  end

  def has_next_event_from?(from)
    get_related_event(from).size > 0
  end

  def get_relation_to(target_user)
    relation_to_owner = Relation::NOTHING unless target_user.present?
    relation_to_owner = Relation::HIMSELF if target_user.present? && target_user.id == self.id

    unless relation_to_owner
      followers = self.followed.map(&:id)
      followings = self.following.map(&:id)

      if followers.include?(target_user.id) && followings.include?(target_user.id)
        relation_to_owner = Relation::FRIEND
      elsif followers.include?(target_user.id) && !followings.include?(target_user.id)
        relation_to_owner = Relation::FOLLOWED
      else
        relation_to_owner = Relation::NOTHING
      end
    end

    return relation_to_owner
  end

  private
  def get_related_event(from = 0, limit = MAX_SHOWING_EVENTS)
    event_type = Event.event_types.select{|type|
      ["create_list", "create_item", "add_image", "dump", "favorite", "follow", "comment", "image_favorite"].include?(type)
    }.values

    if from && from != 0
      from_option = Event.arel_table[:id].lt(from)
      e = Event.where(from_option)
    else 
      e = Event
    end

    e
      .where(
        event_type: event_type,
        acter_id: self.id
      )
      .order("id DESC")
      .limit(limit)
  end

end
