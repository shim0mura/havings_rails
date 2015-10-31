# == Schema Information
#
# Table name: social_profiles
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  provider     :string(30)
#  uid          :string(160)
#  access_token :string(255)
#  token_secret :string(255)
#  name         :string(255)
#  nickname     :string(255)
#  email        :string(255)
#  url          :string(255)
#  image_url    :string(255)
#  description  :string(255)
#  other        :text(65535)
#  credentials  :text(65535)
#  raw_info     :text(65535)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'test_helper'

class SocialProfileTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
