class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable,
         :authentication_keys => [:email]

  before_create :generate_token
  before_create :set_email_provider

  validates:token, uniqueness: true

  validates :name, presence: true

  # validates_uniqueness_of :email, allow_blank: false, if: :email_need_validate?

  has_many :social_profiles, dependent: :destroy

  has_many :items

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
      p user
      user.save!
    end
    user
  end

  def email_need_validate?
    p 1
    if create_with_oauth
      return false
    elsif email_changed?
      return true
    elsif persisted?
      p 2
      return false
    else
      p 3
      return true
    end
  end

  def email_required?
    if create_with_oauth
      return false
    else 
      return true
    end
  end

  def password_required?
    return false if create_with_oauth
    return true
  end

end
