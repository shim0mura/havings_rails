# == Schema Information
#
# Table name: timers
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  list_id       :integer          not null
#  user_id       :integer          not null
#  next_due_at   :datetime         not null
#  over_due_from :datetime
#  is_repeating  :boolean          default(FALSE), not null
#  properties    :text(65535)
#  is_deleted    :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  is_active     :boolean          default(TRUE), not null
#

require 'test_helper'

class TimerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
