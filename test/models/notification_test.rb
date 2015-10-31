# == Schema Information
#
# Table name: notifications
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  unread_events :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  read_events   :string(255)
#

require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
