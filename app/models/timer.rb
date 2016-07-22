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

class Timer < ActiveRecord::Base

  MAX_COUNT_PER_LIST = 3

  belongs_to :list, :foreign_key => "list_id", :class_name => "Item"

  default_scope -> { where(is_deleted: false, is_active: true) }

  # 1回限りのタスクで且つdone_taskされているものも取りたい場合
  scope :without_deleted, -> { unscoped.where(is_deleted: false) }

  # 削除済みのものや1回限りのタイマーを含める
  scope :all_timers, ->(user_id, list_id = nil){
    if list_id
      unscoped.where(
        user_id: user_id,
        list_id: list_id
      )
    else
      unscoped.where(
        user_id: user_id
      )
    end
  }

  validates :name, presence: true
  validate :is_valid_next_due_time?

  def is_valid_next_due_time?
    current = Time.now
    if current > next_due_at
      errors.add(:next_due_at, " is invalid")
    end
  end

  def self.done_task_count(user_id, list_id = nil)
    timers = all_timers(user_id, list_id)
    tasks = Event.done_tasks(timers.map(&:id))
    tasks.count
  end

  def self.done_tasks(user_id, list_id = nil)
    timers = all_timers(user_id, list_id)
    tasks = Event.done_tasks(timers.map(&:id))

    result = timers.map do |timer|
      hash = {
        timer: timer.to_light
      }
      events = []
      tasks.each do |t|
        # events << t.properties if t.related_id == timer.id
        if t.related_id == timer.id
          events << JSON.parse(t.properties)["done_date"]
        end
      end

      # 削除済みのもので一度もタスクが行われてないもの
      # （作成ミスと思われるもの）は含めない
      next if events.empty? && timer.is_deleted

      n = events.size
      0.upto(n - 2) do |i|
        (n - 1).downto(i + 1) do |j|
          # if JSON.parse(events[j])["done_date"] < JSON.parse(events[j - 1])["done_date"]
          if events[j] < events[j - 1]
            events[j], events[j - 1] = events[j - 1], events[j]
          end
        end
      end

      hash[:events] = events
      hash
    end.compact
  end

  def events
    event_type = Event.event_types.select{|type|
      ["timer", "done_task"].include?(type)
    }.values
    Event.where(
      event_type: event_type,
      related_id: self.id,
      is_deleted: false
    )
  end

  # タイマーの期限きれた時の処理
  # 基本は定期実行ジョブから叩く
  def pass_due_time(now = Time.now)
    return if next_due_at > Time.now

    self.over_due_from = next_due_at unless self.over_due_from
    self.latest_calc_at = next_due_at
    self.next_due_at = get_next_due_at

    # TODO: ここのwhileに入った場合のログを取る
    #       基本的に定期実行ジョブが死んでない限りここには入らないはずだけど
    #       何かを見落としてここに入る場合があるかも
    while self.next_due_at < now do
      self.latest_calc_at = next_due_at
      self.next_due_at = get_next_due_at
    end

    self.save!

    event = Event.create(
      event_type: :timer,
      acter_id: self.user_id,
      related_id: self.id,
      properties: {
        over_at: now
      }.to_json
    )

    User.find(self.user_id).notification.add_unread_event(event)
  end

  # タスク完了時のnext_due_atを求める
  # 期限日前にタスクを終わらせようとする場合はnext_due_atの次の期限日を返す
  # 期限日後にタスクを終わらせようとする場合はnext_due_atをそのまま返す
  def get_next_due_at_when_task_done
    return nil unless is_repeating
    # 毎週金曜の設定でその日が10/17(土)かつ10/16(金)のタスクを終わらせてない場合
    # next_due_atは10/23(金)になっている
    # タスクは通知後に完了するという使い方、つまりタスクの期限オーバーになる場合が多いはず
    # なのでその場合は有無を言わさずnext_due_atが次のタスク期限日になる
    return next_due_at if over_due_from

    # 毎週金曜の設定でその日が10/15(木)かつnext_due_atが10/16(金)の場合
    # 10/16のタスクを終わらせた事になるので
    # 現状のnext_due_atのまた次のnext_due_at(10/23)を返す
    return get_next_due_at
  end

  # タスクが期限までに終了しているかに関わらず
  # 次の候補日を取得する
  def get_next_due_at
    props = JSON.parse(properties)

    next_due = next_due_at

    return next_due unless is_repeating

    candidate_hour = props["notice_hour"].to_i
    candidate_minute = props["notice_minute"].to_i

    # 日にち指定の場合
    if props["repeat_by"].to_i == 0
      candidate_day = props["repeat_by_day"]["day"].to_i
      candidate_month = props["repeat_by_day"]["month_interval"].to_i

      candidate_date = next_due_at

      # if candidate_date.day > candidate_day
      #   candidate_date = candidate_date + (candidate_month + 1).month
      # elsif candidate_date.day == candidate_day
      #   if before_candidate_date?(candidate_date, candidate_hour, candidate_minute)
      #     candidate_date = candidate_date + (candidate_month + 1).month
      #   else
      #     candidate_date = candidate_date + candidate_month.month
      #   end
      # else
      #   candidate_date = candidate_date + candidate_month.month
      # end
      candidate_date = candidate_date + (candidate_month + 1).month

      last_day = candidate_date.end_of_month.day

      if candidate_day >= last_day
        candidate_date = candidate_date.change(day: last_day)
      else
        candidate_date = candidate_date.change(day: candidate_day)
      end

      candidate_date = candidate_date.change(
        hour: candidate_hour,
        min: candidate_minute
      )

    # 曜日指定の場合
    elsif props["repeat_by"].to_i == 1
      candidate_date = next_due_at
      week_number = props["repeat_by_week"]["week"].to_i
      day_of_week = props["repeat_by_week"]["day_of_week"].to_i
      if week_number == 0

        val = (7 - candidate_date.wday + day_of_week) % 7
        if val == 0
          if before_candidate_date?(candidate_date, candidate_hour, candidate_minute)
            val = 7 
          else
            val = 0
          end
        end
        candidate_date = candidate_date + val.days
        candidate_date = candidate_date.change(
          hour: candidate_hour,
          min: candidate_minute
        )

        # candidate_date = next_due + 7.days
      else
        candidate_day = get_day_of_specified_week(candidate_date, week_number, day_of_week)

        if candidate_day == candidate_date.day
          if before_candidate_date?(candidate_date, candidate_hour, candidate_minute)
            candidate_date = next_due_at.next_month
            candidate_day = get_day_of_specified_week(candidate_date, week_number, day_of_week)
          end
        elsif candidate_day < candidate_date.day
          candidate_date = next_due_at.next_month
          candidate_day = get_day_of_specified_week(candidate_date, week_number, day_of_week)
        end

        candidate_date = candidate_date.change(
          day: candidate_day,
          hour: candidate_hour,
          min: candidate_minute
        )
      end
    end

    return candidate_date
  end

  def get_start_at
    props = JSON.parse(properties)
    Time.parse(props["start_at"])
  end

  # TODO: idとtimer_idを変更する
  # idはtimerのidを、timerの属するlistのidはlist_idとして設定
  # timer_controller#json_rendered_timerも合わせて直す
  # webがid=list_id, timer_id=idで必要としてるっぽいのでそこから直す
  def to_light
    properties = JSON.parse(self.properties)

    {
      id:    self.list_id,
      timer_id:    self.id,
      name:  self.name,
      path:  Rails.application.routes.url_helpers.item_path(self.list_id),
      properties: self.properties,
      is_repeating: self.is_repeating,
      is_active: self.is_active && !self.is_deleted,
      notice_hour: properties["notice_hour"].to_i,
      notice_minute: properties["notice_minute"].to_i,
      repeat_by: properties["repeat_by"].to_i,
      repeat_month_interval: properties["repeat_by_day"]["month_interval"].to_i,
      repeat_day_of_month: properties["repeat_by_day"]["day"].to_i,
      repeat_week: properties["repeat_by_week"]["week"].to_i,
      repeat_day_of_week: properties["repeat_by_week"]["day_of_week"].to_i
    }
  end

  private
  def before_candidate_date?(candidate_date, hour, minute)
    candidate = candidate_date.change(
      sec: 0, usec: 0
    )
    compared = candidate_date.change(
      hour: hour,
      min: minute,
      sec: 0, usec: 0
    )

    candidate >= compared
  end

  def get_day_of_specified_week(candidate_date, week_number, day_of_week)
    first_day_week_of_month = candidate_date.beginning_of_month.wday
    last_day = candidate_date.end_of_month.day

    first_candidate_day = day_of_week - first_day_week_of_month + 1

    if first_candidate_day <= 0
      first_candidate_day = first_candidate_day + 7
    end

    day = first_candidate_day + (7 * (week_number - 1))

    while day > last_day
      day = day - 7
    end

    return day
  end

end
