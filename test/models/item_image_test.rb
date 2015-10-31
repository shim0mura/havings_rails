# == Schema Information
#
# Table name: item_images
#
#  id         :integer          not null, primary key
#  image      :string(255)
#  item_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class ItemImageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
