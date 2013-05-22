# this will be assign to Webmate.Auth
#   {
#     token:              "string"
#     getToken:           "function(callback)"
#     isAuthorized:       "function()"
#   }
#
#  token - is reference to currentUserToken. 
#
#  getToken(callback) 
#  - returns current  current user token
#  - callback invoked if/when token will be available
#
#  authorized?
#    returns true if user already received a non-blank token
#
#  for now, delayed applies of callback not implemented

define ['jquery'], ($) ->
  authToken = null

  _setToken = (token) ->
    authToken = token
    if $("meta[name='websocket-token']").length > 0
      $("meta[name='websocket-token']").attr('content', token)
    else
      $('head').append( $("<meta>", { name: 'websocket-token', content: token }))

  _getToken = ->
    if authToken then authToken else $("meta[name='websocket-token']").attr('content')

  _fetchToken = (callback) ->
    $.ajax
      url: "/users/sessions/token"
      dataType: 'JSON',
      success: (data) ->
        if data && data.token
          _setToken(data.token)
          callback.call(window, data.token) if callback

  publicGetToken = (callback) ->
    if publicIsAuthorized()
      callback.call(window, _getToken()) if callback
    else
      _fetchToken(callback)

    _getToken()

   # check null or empty string
  publicIsAuthorized = () ->
    not (not _getToken())

  publicResetToken = () ->
    _setToken(null)

    # return object
  auth = {
    getToken: publicGetToken
    resetToken: publicResetToken
    isAuthorized: publicIsAuthorized
  }

  return auth
