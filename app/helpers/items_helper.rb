module ItemsHelper

  def breadcrumb_html(item, include_self = false)
    return link_to(item.user.name, user_page_path(item.user_id)) + "さんの持ち物" unless item.list_id
    unless item.list.present?
      return link_to(item.user.name, user_page_path(item.user_id)) + "さんの持ち物"

    end

    if include_self
      # result = breadcrumb_html(item.list, include_self) + " > " + tag("br") + link_to(item.name, items_path(item.id))
      result = breadcrumb_html(item.list, include_self) + " > " + tag("br") + link_to(item.name, {controller: :items, action: :show, id: item.id})
    else
      result = breadcrumb_html(item.list, true) + " > " + tag("br")
    end
    return result
  end
  

  def due_date_in_ja(time)
    time.strftime("%Y年%-m月%e日(#{%w(日 月 火 水 木 金 土)[time.wday]})%k時%M分")
  end

  # NOTICE: 以下のメソッドたちはtimerのmodelに移したほうがいい？
  def remaining_time_string(due_time)
    remaining_seconds = remaining_time(due_time)
    is_over = remaining_seconds < 0
    remaining_seconds = remaining_seconds.abs

    str = time_to_str(remaining_seconds)

    if is_over
      return str + "オーバー"
    else
      return "あと" + str
    end
  end

  def remaining_time(due_time)
    (due_time - Time.now).to_i
  end

  def remaining_percent(due_at, start_at)
    now = Time.now
    return 100 if now > due_at
    100 - (((due_at - now) / (due_at - start_at)) * 100).to_i
  end

  def remaining_bar_style(due_at, start_at)
    now = Time.now
    return 0 if now > due_at
    color_h = (((due_at - now) / (due_at - start_at)) * 130).to_i
  end

end
