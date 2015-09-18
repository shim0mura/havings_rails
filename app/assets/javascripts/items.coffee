# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on 'click', '.timeline .add-timeline .more', ->

  button_more = $(@)
  parent = $(@).parent()
  timeline = parent.parent()

  last_event_id = $(@).prev('#last_event_id').val()
  $.ajax {
    url: location.href + '/timeline',
    data: 'from=' + last_event_id,
    beforeSend: (xhr, options)->
      button_more.css('display', 'none')
      button_more.next('div').css('display', 'inline-block')
    success: (result, status, xhr)->
      parent.remove()
      timeline.append(result)
    error: (xhr, status, error)->
      button_more.css('display', 'block')
      button_more.next('div').css('display', 'none')
      createToast("エラーが発生しました。時間を置いて再度お試しください。")
  }
