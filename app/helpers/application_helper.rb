module ApplicationHelper

  def notification_str_by_type(notification)
    str = nil

    case notification[:type]
    when :timer
      tasks = []
      notification[:acter].slice(0...Notification::MAX_SHOWING_ACTER_IN_WEB).each do |a|
        tasks << link_to(a[:name], a[:path])
      end
      # return false if task.empty?
      str = "タスク: "
      str = str + tasks.join(", ")
      if notification[:acter].size > Notification::MAX_SHOWING_ACTER_IN_WEB
        str = str + "ほか#{notification.size - MAX_EVENT_SHOWING}つのタスク"
      end
      str = str + "の期限が切れました。"

    when :favorite
      acter = []
      notification[:acter].slice(0...Notification::MAX_SHOWING_ACTER_IN_WEB).each do |a|
        acter << link_to(a[:name] + "さん", a[:path])
      end
      str = acter.join(", ")

      if notification[:acter].size > Notification::MAX_SHOWING_ACTER_IN_WEB
        str = str + "ほか#{notification.size - MAX_EVENT_SHOWING}人"
      end

      link_to_item = link_to(notification[:target].first[:name], notification[:target].first[:path])

      str = str + "が#{link_to_item}をお気に入りしました。"

    when :comment
      acter = []
      notification[:acter].slice(0...Notification::MAX_SHOWING_ACTER_IN_WEB).each do |a|
        acter << link_to(a[:name] + "さん", a[:path])
      end
      str = acter.join(", ")

      if notification[:acter].size > Notification::MAX_SHOWING_ACTER_IN_WEB
        str = str + "ほか#{notification.size - MAX_EVENT_SHOWING}人"
      end

      link_to_item = link_to(notification[:target].first[:name], notification[:target].first[:path])

      str = str + "が#{link_to_item}にコメントしました。"

    when :follow
      follower = []
      notification[:acter].slice(0...Notification::MAX_SHOWING_ACTER_IN_WEB).each do |a|
        follower << link_to(a[:name], a[:path])
      end

      return false if follower.empty?

      str = follower.join(", ")
      if notification[:acter].size > Notification::MAX_SHOWING_ACTER_IN_WEB
        str = str + "ほか#{notification.size - MAX_EVENT_SHOWING}人"
      end
      str = str + "があなたをフォローしました。"

    end

    return str
  end

  def time_to_str(seconds)
    if seconds < 60 * 60
      str = (Time.parse("1/1") + seconds).strftime("%-M分")
    elsif seconds < 60 * 60 * 24
      str = (Time.parse("1/1") + seconds).strftime("%-H時間")
    else
      day = (seconds / (60 * 60 * 24)).to_i
      str = day.to_s + "日"
    end
    return str
  end

  def category_list(obj)
    content_tag(:ul, recursive_category(obj), class: "list")
  end

  def recursive_category(obj)
    html = ""
    obj.each do |item|
      # next unless item[:item][:is_list]
      next unless item[:is_list]
      children = ""
      item[:owning_items].each do |child|
        # if child[:item][:is_list]
        if child[:is_list]
          children = children.html_safe + recursive_category([child])
        end
      end
      children = content_tag(:ul, children) unless children.empty?
      # current_html = content_tag(:li, link_to(item[:item][:name] + "(#{item[:count]})", item[:item][:path]) + children)
      current_html = content_tag(:li, link_to(item[:name] + "(#{item[:count]})", item[:path]) + children)

      html = html.html_safe + current_html
    end
    html
  end

  def repeating_task_to_str(props_by_json)
    if props_by_json["repeat_by"].to_i == 0
      case(props_by_json["repeat_by_day"]["month_interval"].to_i)
      when(0)
        month_interval = "毎月 "
      when(1)
        month_interval = "2ヶ月に1回 "
      when(2)
        month_interval = "3ヶ月に1回 "
      when(3)
        month_interval = "4ヶ月に1回 "
      when(5)
        month_interval = "半年に1回 "
      end
      day = props_by_json["repeat_by_day"]["day"].to_s + "日"
      str = month_interval + day
    else
      case(props_by_json["repeat_by_week"]["week"].to_i)
      when(0)
        week = "毎週 "
      when(1)
        week = "毎月第一週 "
      when(2)
        week = "毎月第二週 "
      when(3)
        week = "毎月第三週 "
      when(4)
        week = "毎月第四週 "
      when(5)
        week = "毎月最終週 "
      end
      wdays = ["日", "月", "火", "水", "木", "金", "土"]
      day_of_week = wdays[props_by_json["repeat_by_week"]["day_of_week"].to_i]

      str = week + day_of_week + "曜日"
    end
    return str + "に通知"
  end

end
