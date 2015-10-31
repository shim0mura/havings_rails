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

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
