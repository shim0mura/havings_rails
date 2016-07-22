json.timers timers do |timer|
  json.extract! timer, :id, :name, :list_id, :next_due_at, :over_due_from, :is_repeating, :latest_calc_at, :is_active, :is_deleted
  properties = JSON.parse(timer.properties)
  json.notice_hour properties["notice_hour"].to_i
  json.notice_minute properties["notice_minute"].to_i
  json.repeat_by properties["repeat_by"].to_i
  json.repeat_month_interval properties["repeat_by_day"]["month_interval"].to_i
  json.repeat_day_of_month properties["repeat_by_day"]["day"].to_i
  json.repeat_week properties["repeat_by_week"]["week"].to_i
  json.repeat_day_of_week properties["repeat_by_week"]["day_of_week"].to_i
end
json.can_add_timer can_add_timer
