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
        events << t.properties if t.related_id == timer.id
      end

      # 削除済みのもので一度もタスクが行われてないもの
      # （作成ミスと思われるもの）は含めない
      next if events.empty? && timer.is_deleted

      n = events.size
      0.upto(n - 2) do |i|
        (n - 1).downto(i + 1) do |j|
          if JSON.parse(events[j])["done_date"] < JSON.parse(events[j - 1])["done_date"]
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
    self.next_due_at = get_next_due_at

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
    # タスクは通知後に完了する場合、つまりタスクの期限オーバーの場合が多いはず
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

    # 日にち指定の場合
    if props["repeat_by"] == "0"
      candidate_day = props["repeat_by_day"]["day"].to_i
      candidate_month = props["repeat_by_day"]["month_interval"].to_i

      candidate_date = next_due + (candidate_month + 1).month

      last_day = candidate_date.end_of_month.day

      if candidate_day >= last_day
        candidate_date = candidate_date.change(day: last_day)
      end

    # 曜日指定の場合
    elsif props["repeat_by"] == "1"
      if props["repeat_by_week"]["week"] == "0"
        candidate_date = next_due + 7.days
      else
        week_number = props["repeat_by_week"]["week"].to_i
        day_of_week = props["repeat_by_week"]["day_of_week"].to_i
        candidate_date = next_due.next_month

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

        candidate_date = candidate_date.change(day: day)

      end
    end

    return candidate_date
  end

  def get_start_at
    props = JSON.parse(properties)
    Time.parse(props["start_at"])
  end


  def to_light
    {
      id:    self.list_id,
      timer_id:    self.id,
      name:  self.name,
      path:  Rails.application.routes.url_helpers.item_path(self.list_id),
      properties: self.properties,
      is_repeating: self.is_repeating,
      is_active: self.is_active && !self.is_deleted
    }
  end

end
