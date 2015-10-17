$ ->
  already_follow = "already-follow"

  followed_span = "フォロー中"
  unfollow_span = "解除する"
  follow_span = "フォロー"
  followed_icon = "person"
  unfollow_icon = "cancel"
  follow_icon = "person_add"

  $('.follow').hover(
    (e) ->
      if $(@).hasClass(already_follow)
        $(@).find("i").html(unfollow_icon)
        $(@).find("span").first().html(unfollow_span)
    (e) ->
      if $(@).hasClass(already_follow)
        $(@).find("i").html(followed_icon)
        $(@).find("span").first().html(followed_span)
  )

  $(document).on "click", ".follow", (e)->
    if $(@).hasClass("not-sigined-in")
      alert("フォローするにはログインしてください。")
    else
      button = $(@)
      if $(@).hasClass(already_follow)
        form = button.prevAll('form.unfollow-user')
        type = form.find('[name=_method]').val()
      else
        form = button.prevAll('form.follow-user')
        type = 'POST'

      $.ajax {
        url: form.attr('action'),
        type: type,
        data: new FormData(form.get()[0]),
        processData: false,
        contentType: false
        success: (result, status, xhr)->
          button.toggleClass(already_follow)
          if button.hasClass(already_follow)
            button.find("span").first().html("フォロー中")
            button.find("i").html("person")
          else
            button.find("span").first().html("フォロー")
            button.find("i").html("person_add")
      }
