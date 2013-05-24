define ['backbone','webmate'], (bb, webmate) ->

  methodMap =
    create: "POST"
    update: "PUT"
    patch: 'PATCH'
    delete: "DELETE"
    read: "GET"
    read_all: "GET"

  getModelChannel = (model) ->
    channel_name = _.result(model, 'channel')
    if !channel_name and model.collection
      channel_name = _.result(model.collection, 'channel')
    channel_name or= 'socket'

    channel = Webmate.channels[channel_name]
    if channel.opened()
      return channel
    else
      return null

  # get an alias
  window.Backbone.sync_with_ajax = window.Backbone.sync

  # method = update
  # model - single model
  # options: success(), error(), parse, validate
  window.Backbone.sync = (method, model, options) ->
    options or= {}
    sync_transport = 'ajax'
    channel = getModelChannel(model)
    if options.transport
      sync_transport = options.transport
    else if window.Webmate.websocketsEnabled && channel
      sync_transport = 'websockets'

    # use default behaviour
    if sync_transport == 'ajax'
      window.Backbone.sync_with_ajax(method, model, options)
    else
      # websocket messages protocol.
      #   method: 'post'
      #   path: '/projects/:project_id/tasks'
      #   params: {}
      #   metadata: {} # data to passback
      url = _.result(model, 'url')
      collection_url = if model.collection then _.result(model.collection, 'url') else url

      metadata = {
        collection_url: collection_url,
        method: method,
        user_websocket_token: Webmate.Auth.getToken()
      }

      if model instanceof Backbone.Model
        metadata.id = model.id

      packet_data = {
        method: methodMap[method],
        path: url,
        metadata: metadata,
        params: {}
      }
      if (method == 'create' || method == 'update' || method == 'patch')
        packet_data.params = JSON.stringify(options.attrs || model.toJSON(options))

      # catch single model work
      #model.listenTo(channel, callbacks)

      channel.send(url, packet_data, methodMap[method])
      model.trigger "request", model
