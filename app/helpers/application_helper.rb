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

    end

    return str
  end

  def time_to_str(seconds)
    if seconds < 60 * 60
      str = (Time.parse("1/1") + seconds).strftime("%-M分")
    elsif seconds < 60 * 60 * 24
      str = (Time.parse("1/1") + seconds).strftime("%-H時間")
    else
      day = seconds / (60 * 60 * 24)
      str = day.to_s + "日"
    end
    return str
  end

end
