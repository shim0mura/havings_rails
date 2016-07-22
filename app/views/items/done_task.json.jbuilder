json.list do
  json.extract! @item.to_light, :id, :name, :count, :path, :image
end

json.tasks @tasks do |task|

  json.timer do
    json.id task[:timer][:id]
    json.list_id task[:timer][:list_id]
    json.name task[:timer][:name]
    json.is_active task[:timer][:is_active]
    json.is_repeating task[:timer][:is_repeating]

    json.notice_hour task[:timer][:notice_hour]
    json.notice_minute task[:timer][:notice_minute]
    json.repeat_by task[:timer][:repeat_by]
    json.repeat_month_interval task[:timer][:repeat_month_interval]
    json.repeat_day_of_month task[:timer][:repeat_day_of_month]
    json.repeat_week task[:timer][:repeat_week]
    json.repeat_day_of_week task[:timer][:repeat_day_of_week]

  end

  json.events task[:events]

end
