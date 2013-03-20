# Improved Backbone Sync
(->
  methodMap =
    create: "POST"
    update: "PUT"
    patch: 'PATCH'
    delete: "DELETE"
    read: "GET"

  getUrl = (object, method) ->
    channel = _.result(object, "channel")
    if channel
      "/#{channel}/#{object.collectionName()}/#{method}"
    else
      return null unless object and object.url
      (if _.isFunction(object.url) then object.url() else object.url)

  getChannel = (object) ->
    return null unless object and object.channel
    (if _.isFunction(object.channel) then object.channel() else object.channel)

  urlError = ->
    throw new Error("A 'url' property or function must be specified")

  window.Backbone.sync = (method, model, options) ->
    type = methodMap[method]
    data = {}
    if model and (method is "create")
      data['_cid'] = model.cid
    if model and (method is "create" or method is "update" or method is 'patch')
      data[model.resourceName()] = (options.attrs || model.toJSON())
    if model and (method is "update" or method is 'patch')
      delete data[model.resourceName()][model.idAttribute]
    if model and (method is "delete" or method is "update" or method is 'patch')
      data[model.idAttribute] = model.id
    if window.WebSocket
      token = $('meta[name="websocket-token"]').attr('content')
      data.user_websocket_token = token
      client = Webmate.channels[getChannel(model)]
      client.send("#{model.collectionName()}/#{method}", data, type)

      model.trigger "request", model
    else
      params =
        type: type
        dataType: "json"

      # Ensure that we have a URL.
      params.url = getUrl(model, method) or urlError()
      params.contentType = "application/json"
      params.data = JSON.stringify(data)

      # Don't process data on a non-GET request.
      params.processData = false if params.type isnt "GET"
      success = options.success
      options.success = (resp, status, xhr) ->
        success resp.response, status, xhr  if success
        model.trigger "sync", model, resp.response, options

      error = options.error
      options.error = (xhr, status, thrown) ->
        error model, xhr, options  if error
        model.trigger "error", model, xhr, options
      # Make the request, allowing the user to override any Ajax options.
      xhr = Backbone.ajax(_.extend(params, options))
      model.trigger "request", model, xhr, options

).call(this)
