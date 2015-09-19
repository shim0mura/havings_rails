$ ->

  fab_form_id = "#fab-action-form"
  modal_id = "#modal-overlay"

  set_modal_position = ->
    w = $(window).width()
    h = $(window).height()
    top = $('header.header').outerHeight(true) + 20
    from_bottom = 90
    fab_form = $(fab_form_id)
    cw = fab_form.outerWidth();
    ch = fab_form.outerHeight(true);
    if (h - (ch + top + from_bottom)) < 0
      height = h - (top + from_bottom)
    else
      height = ch
    pxleft = ((w - cw)/2);
    pxtop = ((h - height)/2);
    fab_form.css
      left: pxleft + "px"
      top: pxtop + "px"
      height: height + "px"

  $('.action-button-wrapper').on("click", ->
    $(@).blur()
    form_type = $(@).data("form-type")
    return false if ($("#modal-overlay")[0])
    $(".page-content").append('<div id="modal-overlay"></div>')
    $("#modal-overlay").fadeIn("fast");
    $(fab_form_id).fadeIn("fast");
    $("#" + form_type).show();
    $('.sending-error').css('display', 'none')
    set_modal_position()
  )

  hide_overlay = ->
    $(modal_id).fadeOut("fast", ->
      $(@).remove()
      $(fab_form_id).hide()
      $(fab_form_id + " > div").hide()
    )

  $(document).on("click", modal_id, hide_overlay)

  states = ['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
    'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii',
    'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
    'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota',
    'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
    'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
    'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'
  ]

  countries = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.whitespace,
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    local: states
  })

  $('#fab-action-form  .list-name.typeahead').typeahead(null, {
    source: countries,
  })

  $("span.twitter-typeahead").css
    display: "block"

  $("ul.item-tags").on "click", ->
    $(@).addClass("onfocus")
  $("ul.item-tags").on "blur", "input", ->
    $("ul.item-tags").removeClass("onfocus")

  $('ul.item-tags').tagit
    fieldName:     'item[tag_list]'
    singleField:   true
    availableTags: states

  $(document).on 'change', 'input[type=file].upload-item-image', ->
    file = $(@).prop('files')[0]

    if !file.type.match('image.*')
      $(@).val('')
      return

    reader = new FileReader()
    reader.onload = =>
      img = $('<img>').attr('src', reader.result)
      $(@).css('display', 'none')
      $(@).next('.thumbnail').html(img)
    reader.readAsDataURL(file)

    addings = $(@).parent().clone()
    addings.find('input[type=file].upload-item-image').val('').css('display', 'block')
    $(@).nextAll('.adding-text').removeClass('adding-text').addClass('delete-thumbnail').html('delete')
    $(@).parent().parent().append(addings)

  $(document).on 'click', '.delete-thumbnail', ->
    if $(@).prevAll('.upload-item-image').prop('files')[0] == undefined
      return
    $(@).parent().remove()

  $('label.check-dump-item').on 'click', (e)->
    target = $(e.target)
    return unless target.hasClass('mdl-checkbox__input')
    if target[0].checked
      $(@).nextAll('.garbage-reason').show('fast')
    else
      $(@).nextAll('.garbage-reason')
        .hide('fast')
        .find('textarea').val('')

  $('.existing-image .delete-image-button').on 'click', ->
    klass = 'cancel-delete'
    if $(@).hasClass(klass)
      $(@).removeClass(klass)
      $(@).html("削除")
      $(@).next('.image-delete-flag').prop("checked", false)
      $(@).prev('.image-description').css('display', 'none')
    else
      $(@).addClass(klass)
      $(@).html("削除取消")
      $(@).next('.image-delete-flag').prop("checked", true)
      $(@).prev('.image-description').css('display', 'block')


  $('.send-form').on 'click', (e)->
    button = $(@)
    form = $(@).closest('form')

    if form.find('[name=method]').length < 1
      type = 'POST'
    else
      type = form.find('[name=_method]').val()

    formData = new FormData( form.get()[0] );

    $.ajax {
      url: form.attr('action'),
      type: type,
      data: formData,
      processData: false,
      contentType: false,
      beforeSend: (xhr, options)->
        # validation
        name = form.find('input[name="item[name]"]')
        if name.length > 0 && name.val().trim() == ''
          $('.validation-error').css('display', 'block')
          return false
        else
          $('.validation-error').css('display', 'none')
        button.attr('disabled', 'disabled')
      complete: (xhr, textStatus)->
        button.removeAttr('disabled')
      success: (result, status, xhr)->
        $('.validation-error').css('display', 'none')
        $('.sending-error').css('display', 'none')
        hide_overlay()
        createToast(form.prev('h4').html() + "をしました。")
      error: (xhr, status, error)->
        $('.sending-error').css('display', 'block')
    }
