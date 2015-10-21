class User < ActiveRecord::Base
  mount_uploader :image, AvatarUploader

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable,
         :authentication_keys => [:email]

  before_create :generate_token
  before_create :set_email_provider
  after_create  :create_notification

  validates:token, uniqueness: true

  validates :name, presence: true

  # validates_uniqueness_of :email, allow_blank: false, if: :email_need_validate?

  has_many :social_profiles, dependent: :destroy

  has_many :items

  has_many :comments

  has_one :notification

  has_many :favorites

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

  def thumbnail
    # TODO:social_profileの画像をどうにかしてuserカラムの中に収めたい
    #      その分sqlを1本減らしたい
    if image && image.file.exists?
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
      path:  Rails.application.routes.url_helpers.user_page_path(self.id)
    }
  end

  def item_tree(current = nil, start_at = nil, items = nil, queue = nil, result = nil)
    if start_at
      queue = Item.where(id: start_at).to_a
    end

    if items.nil?
      items = Item.where(user_id: self.id).to_a
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
      hash = {
        item: parent_item.to_light,
        children: nil,
        current: (parent_item.id == current),
        count: parent_item.count
      }
      items.delete_if do |item|
        if item.list_id == parent_item.id
          child_queue << item
          true
        end
      end
      hash[:children] = item_tree(current, nil, items, child_queue, Marshal.load(Marshal.dump(result)))
      children_count = hash[:children].inject(0){|sum, item| sum + item[:count]} || 0
      hash[:count] = hash[:count] + children_count

      current_result << hash
    end
    current_result
  end

end
