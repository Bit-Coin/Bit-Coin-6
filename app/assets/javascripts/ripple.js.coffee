# ripple.js should be included on all pages

Ripple =
  adjustElementsForWidth: ->
    if $(window).width() < 992
      $('.container').toggleClass('container-fluid').removeClass('container')
    else 
      $('.container-fluid').toggleClass('container').removeClass('container-fluid')

  sessionTokenized: ->
    return $('body').data('session-tokenized')

  adjustWhenTokenized: ->
    if this.sessionTokenized()
      return true # noop

  findCompanyByDomain: (domain) ->
    $.grep Ripple.companies, (company) ->
      company.domain == domain

  validEmail: (email) ->
    regex = /^([a-zA-Z0-9_.+-])+\@(([a-zA-Z0-9-])+\.)+([a-zA-Z0-9]{2,4})+$/;
    regex.test(email);

  testMessage: ->
    'Your JavaScript is being tested!'

  flashError: (message) ->
    Ripple.flashMessage(message, 'alert-danger')

  flashWarning: (message) ->
    Ripple.flashMessage(message, 'alert-warning')
    
  flashMessage: (message, bootstrapStyle) ->
    msgEl = $('<div class="alert alert-dismissible" role="alert">\
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">\
      <span aria-hidden="true">&times;</span></button></div>').addClass(bootstrapStyle)
    bodyEl = $('<span></span>').html(message)
    msgEl.append(bodyEl)
    flashEl = $('body .flash-messages').get(0)
    if flashEl
      $(flashEl).empty().append(msgEl)
    else
      flashEl = $('<div class="flash-messages"></div>').append(msgEl)
      $('body .container').first().prepend(flashEl)
      window.scroll(0,0)

window.Ripple = Ripple

Array.prototype.containsArray = (array) ->
  return -1 unless array instanceof Array
  elMatch = false
  this.forEach (element, index, source) ->
    return (index - 1) if elMatch
    elMatch = true
    element.forEach (value, index, source) ->
      elMatch = false if value != array[index]
  if elMatch
    return (this.length - 1)
  else
    return -1
