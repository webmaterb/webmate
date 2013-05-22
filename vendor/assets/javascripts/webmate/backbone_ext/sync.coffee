define ['backbone','webmate'], (bb, webmate) ->

  methodMap =
    create: "POST"
    update: "PUT"
    patch: 'PATCH'
    delete: "DELETE"
    read: "GET"
    read_all: "GET"

  # get an alias
  window.Backbone.sync_with_ajax = window.Backbone.sync

  # method = update
  # model - single model
  # options: success(), error(), parse, validate
  window.Backbone.sync = (method, model, options) ->
    options or= {}
    sync_transport = 'ajax'
    if options.transport
      sync_transport = options.transport
    else if window.Webmate.websocketsEnabled && Webmate.channels['api'].opened()
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
        #model.listenTo(Webmate.channels['api'], "
      #else if model instanceof Backbone.Collection

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

      Webmate.channels['api'].send(url, packet_data, methodMap[method])
      model.trigger "request", model
