$ ->

  $(document).on "click", "div.post-comment", (e)->
    if $(@).hasClass("not-sigined-in")
      alert("コメントを投稿するにはログインしてください。")
    else
      button = $(@)
      form = button.closest('form.post-comment')
      type = 'POST'

      $.ajax {
        url: form.attr('action'),
        type: type,
        data: new FormData(form.get()[0]),
        processData: false,
        contentType: false
        beforeSend: (xhr, options)->
          unless form.find('textarea').val()
            form.find('.validation-error').css('display', 'block')
            return false
          button.attr('disabled', 'disabled')
        success: (result, status, xhr)->
          form.find('.validation-error').css('display', 'none')
          form.find('.sending-error').css('display', 'none')
          comment = form.prev().clone()
          if result.commenter.image
            comment.find(".commenter img").attr("src", result.commenter.image)
          else
            comment.find(".commenter img").remove()
          comment.find(".commenter a").attr("href", "/user/" + result.commenter.id)
          comment.find(".commenter .commenter-name a").html(result.commenter.name)
          comment.find(".commenter .commenter-name span").remove()
          comment.find(".commenter .commented-time").html("今")
          comment.find(".comment-text").html(form.find("textarea").val())
          form.before(comment)
          form.find("textarea").val("")
          createToast('コメントを投稿しました。')
        complete: (xhr, textStatus)->
          form.find('.validation-error').css('display', 'none')
          button.removeAttr('disabled')
        error: (xhr, status, error)->
          form.find('.sending-error').css('display', 'block')
      }

  $(document).on "click", "div.commenter .commenter-name i", (e)->
    button = $(@)
    form = button.prevAll('form.delete-comment')
    type = 'DELETE'

    $.ajax {
      url: form.attr('action'),
      type: type,
      data: new FormData(form.get()[0]),
      processData: false,
      contentType: false
      beforeSend: (xhr, options)->
        unless confirm("このコメントを削除します。")
          return false
        button.attr('disabled', 'disabled')
      success: (result, status, xhr)->
        button.closest("div.comment-post").remove()
        form.next('.sending-error').css('display', 'none')
        createToast('コメントを削除しました。')
      complete: (xhr, textStatus)->
        form.next('.validation-error').css('display', 'none')
        button.removeAttr('disabled')
      error: (xhr, status, error)->
        form.next('.sending-error').css('display', 'block')
    }
