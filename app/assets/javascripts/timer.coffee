$ ->

  day_of_week = ['日', '月', '火', '水', '木', '金', '土']

  current_date = null

  $.datepicker.setDefaults( $.datepicker.regional[ "ja" ] )

  get_date_string = (date)->
    year = date.getFullYear()
    month = date.getMonth() + 1
    day = date.getDate()
    week = date.getDay()
    hour = date.getHours()
    min = ('0' + date.getMinutes()).slice(-2)
    year + '年' + month + '月' + day + '日' + '(' + day_of_week[week] + ') ' + hour + '時' + min + '分'

  get_start_at = (parent)->
    # parent.find(".tmp-next-due-at").data("tmp-date")
    # parent.find(".default-next-due-at").data("tmp-date")
    parent.find(".default-due-date").data("date")

  get_next_due_date = (parent)->
    new Date(parent.find(".next-due-at").val())

  set_next_due_date = (parent, date)->
    # parent.find(".tmp-next-due-at").data("tmp-date", date)
    # parent.find(".next-due-at").data("date", date)
    parent.find(".next-due-at").val(date)
    parent.find(".next-date").find(".date-string").html(get_date_string(date))
    parent.find(".date-picker").datepicker("setDate", date)

  get_last_day = (year, month)->
    new Date(year, month + 1, 0).getDate()

  set_default = (elm)->
    default_val = elm.find(".default-due-date").val()
    if default_val
      # editの場合
      date = new Date(default_val)
    else
      # addの場合
      date = new Date
      date.setSeconds(0)

      date.setHours(date.getHours() + 1)

      minutes = date.getMinutes()
      if minutes > 0 && minutes < 15
        date.setMinutes(15)
      else if minutes < 30
        date.setMinutes(30)
      else if minutes < 45
        date.setMinutes(45)
      else
        date.setMinutes(0)
        date.setHours(date.getHours() + 1)

    elm.find(".date-picker").datepicker("setDate", date)

    minutes = date.getMinutes()
    if minutes == 0
      minutes = "00"

    # 共通処理
    elm.find(".default-due-date").data("date", date)
    # elm.find(".next-due-at").data("date", date)
    elm.find(".next-due-at").val(date)
    elm.find(".next-date").find(".date-string").html(get_date_string(date))

    elm.find(".hour").val(date.getHours())
    elm.find(".minute").val(minutes)

    elm.find(".by-day").val(date.getDate())
    elm.find(".by-week").val(date.getDay())

    properties = elm.find(".default-properties").val()
    if properties
      properties = JSON.parse(properties)
    else
      properties =
        is_repeating: false
        start_at: new Date
        repeat_by: 0
        repeat_by_day:
          day: date.getDate()
          month_interval: 0
        repeat_by_week:
          week: 0
          day_of_week: date.getDay()

    unless elm.find(".repeating-or-not input[type='checkbox']").prop("checked") == properties.is_repeating
      elm.find(".repeating-or-not input[type='checkbox']").trigger("click")

    elm.find(".repeat-by input:eq(" + properties.repeat_by + ")").trigger("click")
    elm.find(".repeat-by-day .by-month").val(properties.repeat_by_day.month_interval)
    elm.find(".repeat-by-week .by-week-number").val(properties.repeat_by_week.week)

  set_properties_event = (elm) ->
    elm.find('.repeating-or-not').on 'click', (e)->
      target = $(e.target)
      unless target.hasClass('mdl-checkbox__input')
        return
      if target[0].checked
        $(@).nextAll('.repeat-interval').show('fast')
      else
        $(@).nextAll('.repeat-interval').hide('fast')

    elm.find('.check-repeat-by-day').on 'click', (e)->
      target = $(e.target)
      return unless target.hasClass('mdl-radio__button')
      parent = $(@).closest('.repeat-by')
      parent.nextAll('.repeat-by-day').show('fast')
      parent.nextAll('.repeat-by-week').hide('fast')

    elm.find('.check-repeat-by-week').on 'click', (e)->
      target = $(e.target)
      return unless target.hasClass('mdl-radio__button')
      parent = $(@).closest('.repeat-by')
      parent.nextAll('.repeat-by-day').hide('fast')
      parent.nextAll('.repeat-by-week').show('fast')

  set_properties = (elm)->
    unless elm.find('.repeating-or-not input[type="checkbox"]')[0].checked
      elm.find('.repeat-interval').hide()
    if elm.find('.check-repeat-by-day')[0].checked
      elm.find('.repeat-by-day').show()
      elm.find('.repeat-by-week').hide()
    if elm.find('.check-repeat-by-week')[0].checked
      elm.find('.repeat-by-day').hide()
      elm.find('.repeat-by-week').show()

  set_time = ->
    $(".edit-timer").each ->
      # 全部js側でレンダリングする
      # propertiesに入ってる繰り返し条件なども全部

      set_default($(@))

      change_time = ->
        time = $(@).val()
        parent = $(@).closest(".edit-timer")
        date = get_next_due_date(parent)
        if $(@).hasClass("hour")
          date.setHours(time)
        else
          date.setMinutes(time)

        set_next_due_date(parent, date)

      change_by_day = ->
        select_div = $(@).parent()
        candidate_month = select_div.children(".by-month").val() - 0
        candidate_day = select_div.children(".by-day").val() - 0
        parent = $(@).closest(".edit-timer")
        current_date = new Date
        candidate_date = new Date(current_date.getFullYear(), current_date.getMonth(), current_date.getDate())
        last_day = get_last_day(current_date.getFullYear(), current_date.getMonth())

        # 現在9月20日なのに31日を指定した場合のように
        # 当月の最終日よりも進んだ日を選択した場合
        if candidate_day >= last_day
          candidate_date.setDate(last_day)
        else
          candidate_date.setDate(candidate_day)

        candidate_date.setHours(parent.find(".hour").val())
        candidate_date.setMinutes(parent.find(".minute").val())

        # 現在9月20日なのに19日をした場合のように
        # 当月の過ぎた日を選択した場合は翌月以降の19日を次回通知候補日にする
        if current_date > candidate_date
          candidate_date.setMonth(candidate_date.getMonth() + 1)

        # 現在9月30日で31日を選択した場合
        # ここまでの処理では次回通知候補日が10月30日になる
        # なのでそれが10月31日になるよう調整
        # 隔月の処理もここで行う
        # jsのDateの仕様でsetDateのタイミングでmonthも変更される
        # (setDateで9月31日と入力した場合、10月1日に内部的に自動変換される）
        # ので、その場合を考慮してnew Dateしてる
        candidate_date_last_day = get_last_day(candidate_date.getFullYear(), candidate_date.getMonth() + candidate_month)
        if candidate_day >= candidate_date_last_day
          candidate_date = new Date(candidate_date.getFullYear(), candidate_date.getMonth() + candidate_month, candidate_date_last_day, candidate_date.getHours(), candidate_date.getMinutes())
        else
          candidate_date.setMonth(candidate_date.getMonth() + candidate_month)

        set_next_due_date(parent, candidate_date)

      change_by_week = ->

        get_next_week_date = (year, month, day, week)->
          first_day_week_of_month = new Date(year, month, 1).getDay()
          last_day_of_month = new Date(year, month + 1, 0).getDate()
          # today_date = new Date
          today_date = new Date(year, month, day)
          today = today_date.getDate()
          today_week = today_date.getDay()
          val = (7 - today_week + week) % 7
          val = if val == 0 then 7 else val
          day = today + val
          if day > last_day_of_month
            next_date = new Date(year, month + 1, day - last_day_of_month)
          else
            next_date = new Date(year, month, day)
          next_date

        get_what_day_of_week = (year, month, week_number, week)->
          first_day_week_of_month = new Date(year, month, 1).getDay()
          last_day_of_month = new Date(year, month + 1, 0).getDate()
          first_candidate_day = week - first_day_week_of_month + 1
          if first_candidate_day <= 0
            first_candidate_day = first_candidate_day + 7
          day = first_candidate_day + (7 * (week_number - 1))
          while day > last_day_of_month
            day = day - 7
          day

        select_div = $(@).parent()
        candidate_week_number = select_div.children(".by-week-number").val() - 0
        candidate_week = select_div.children(".by-week").val() - 0
        parent = $(@).closest(".edit-timer")
        current_date = new Date

        if candidate_week_number == 0
          candidate_date = get_next_week_date current_date.getFullYear(), current_date.getMonth(), current_date.getDate(), candidate_week
        else
          candidate_day = get_what_day_of_week current_date.getFullYear(), current_date.getMonth(), candidate_week_number, candidate_week
          candidate_date = new Date(current_date.getFullYear(), current_date.getMonth(), candidate_day, current_date.getHours(), current_date.getMinutes())
          if current_date > candidate_date
            candidate_day = get_what_day_of_week current_date.getFullYear(), current_date.getMonth() + 1, candidate_week_number, candidate_week
            candidate_date = new Date(current_date.getFullYear(), current_date.getMonth() + 1, candidate_day, current_date.getHours(), current_date.getMinutes())

        candidate_date.setHours(parent.find(".hour").val())
        candidate_date.setMinutes(parent.find(".minute").val())

        set_next_due_date(parent, candidate_date)

      $(@).find(".hour").change change_time
      $(@).find(".minute").change change_time

      repeat_by_day = $(@).find(".repeat-by-day")
      repeat_by_day.find(".by-month").change change_by_day
      # repeat_by_day.find(".by-day").val(date.getDate())
      repeat_by_day.find(".by-day").change change_by_day

      repeat_by_week = $(@).find(".repeat-by-week")
      repeat_by_week.find(".by-month").change change_by_week
      repeat_by_week.find(".by-week-number").change change_by_week
      repeat_by_week.find(".by-week").change change_by_week

      $(@).find(".clear-form").click =>
        set_default($(@))

      set_properties($(@))
      set_properties_event($(@))

      next_due_date = get_start_at($(@))

      $(@).find(".date-picker").datepicker({
        dateFormat: 'yy年mm月dd日(DD)',
        dayNames: day_of_week,
        defaultDate: next_due_date,
        onSelect: (date_text, instance)->

          # 何故かonSelectをかませてカレンダーのtable要素を取得しようとすると出来ない
          # Datepickerが内部でonSelectを呼ぶ時に何かしてるっぽいけどよくわからない
          # なので今のところは曜日選択時などの次週以降の候補日のクラス変えて表示変えるのは諦める
          parent = $(@).closest(".edit-timer")
          date = get_next_due_date(parent)
          candidate_date = new Date(instance.selectedYear, instance.selectedMonth, instance.selectedDay, date.getHours(), date.getMinutes())

          set_next_due_date($(@).closest(".edit-timer"), candidate_date)
      })

  set_time()


