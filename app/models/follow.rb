# == Schema Information
#
# Table name: follows
#
#  id                :integer          not null, primary key
#  following_user_id :integer          not null
#  followed_user_id  :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Follow < ActiveRecord::Base

  belongs_to :following_user, class_name: User, foreign_key: :following_user_id
  belongs_to :followed_user, class_name: User,   foreign_key: :followed_user_id

  validates :following_user, uniqueness: { scope: [:followed_user_id] }

end
