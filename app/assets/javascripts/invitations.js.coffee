# invitations.js.coffee

$(document).on 'ready', ->
  
  return unless Ripple.givers
    
  givers = new Bloodhound
                datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value')
                queryTokenizer: Bloodhound.tokenizers.whitespace
                local: Ripple.givers
  givers.initialize()

  $('.email').typeahead {
    hint: true
    highlight: true
    minLength: 1
  },{
    source: givers.ttAdapter()
  }

  $('.email').on 'keypress', (e) ->
    k = e.keyCode
    if k == 13 # enter/return
      $(this).blur()
    else if k == 9 # tab.  autocompletes too
      # blur eats tab?
      $(this).blur()
    else if k == 8 # backspace
      if this.value == ''
        e.preventDefault()
        false
    else if k == 32 # space
      e.preventDefault(0)
      false
    else
      true

  $('.email').on 'typeahead:selected', (event, suggestion, dataset) ->
    SubmitInvite(this, suggestion.giver_id, suggestion.value)

  $('.email').on 'typeahead:autocompleted', (event, suggestion, dataset) ->
    SubmitInvite(this, suggestion.giver_id, suggestion.value)

  $('.email.not-persisted').on 'blur', ->
    SubmitInvite(this, $(this).data().giverId, this.value)

  $('#submit-invite').on 'click', ->
    SubmitInvite(this, $(this).data().giverId, this.value)

  $('.deactivate_invitation').on 'click', ->
    if confirm('Delete invitation?')
      invitationId = this.id.split('_')[1]
      $.ajax
        url: '/api/v1/invitations/' + invitationId
        method: 'delete'
        success: (data, status, xhr) ->
          location.reload()
        error: (xhr, status, message) -> 
          Ripple.flashError(message)

  $('.resend_invitation').on 'click', ->
    invitationId = this.id.split('_')[2]
    $.ajax
      url: '/api/v1/invitations/' + invitationId + '/resend'
      method: 'get'
      success: (data, status, xhr) ->
        location.reload()
        # Ripple.flashMessage(xhr.responseText, 'alert-success')
      error: (xhr, status, message) ->
        Ripple.flashError(message)

  $('.invitation-edit').on 'click', ->
    invitationId = this.id.split('_')[2]
    $('#edit_relationship_' + invitationId).show()

SubmitInvite = (element, giver_id, email) ->
  return false unless email
  unless Ripple.validEmail(email)
    Ripple.flashError('Invalid email')
    $(element).focus()
    return false

  if $(element).hasClass('not-persisted')
    $.ajax
      url: '/api/v1/invitations'
      method: 'post'
      data:
          giver_id: giver_id
          email: email
      success: (data, status, xhr) ->
        # TODO make it more one-pagey
        location.reload()
      error: (xhr, status, message) ->
        Ripple.flashError(xhr.responseText)

