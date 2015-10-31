# == Schema Information
#
# Table name: items
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  description      :text(65535)
#  is_list          :boolean          default(FALSE), not null
#  is_garbage       :boolean          default(FALSE), not null
#  count            :integer          default(1), not null
#  garbage_reason   :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer          not null
#  list_id          :integer
#  private_type     :integer          default(0), not null
#  is_deleted       :boolean          default(FALSE), not null
#  count_properties :text(65535)
#

require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
