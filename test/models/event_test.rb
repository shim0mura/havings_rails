# == Schema Information
#
# Table name: events
#
#  id               :integer          not null, primary key
#  event_type       :integer          not null
#  acter_id         :integer          not null
#  suffered_user_id :integer
#  properties       :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  related_id       :integer
#  is_deleted       :boolean          default(FALSE), not null
#

require 'test_helper'

class EventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
