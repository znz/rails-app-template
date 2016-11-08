create_file 'app/assets/javascripts/autogrow.coffee', <<-'COFFEE'
jQuery ($) ->
  jQuery.fn.autogrow = (options) ->
    settings = $.extend {
        extraLineHeight: 15
        timeoutBuffer: 100
      }, options
    self = this
    timerId = self.removeData('timerId')
    if timerId
      clearTimeout timerId
    handler = ->
      self.each (i,e) ->
        scrollHeight = e.scrollHeight
        clientHeight = e.clientHeight
        if clientHeight < scrollHeight
          $(e).height(scrollHeight + settings.extraLineHeight)
      self.removeData('timerId')
    self.data('timerId', setTimeout(handler, settings.timeoutBuffer))
  $(document).on 'keyup.autogrow change.autogrow input.autogrow paste.autogrow', 'textarea', ->
    $(this).autogrow()
  $('textarea').autogrow()
COFFEE
