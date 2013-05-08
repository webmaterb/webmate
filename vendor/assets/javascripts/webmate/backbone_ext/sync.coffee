define (require) ->

  methodMap =
    create: "POST"
    update: "PUT"
    patch: 'PATCH'
    delete: "DELETE"
    read: "GET"
    read_all: "GET"

  # get an alias
  window.Backbone.sync_with_ajax = window.Backbone.sync

  window.Backbone.sync = (method, model, options) ->
    # use default behaviour
    if not (window.Webmate && window.Webmate.websocketsEnabled)
      # clean options?
      window.Backbone.sync_with_ajax(method, model, options)
    else
      # websocket messages protocol.
      #   method: 'post'
      #   path: '/projects/:project_id/tasks'
      #   params: {}
      #   metadata: {} # data to passback
      url = _.result(model, 'url')
      collection_url = if model.collection then _.result(model.collection, 'url') else url

      packet_data = {
        method: methodMap[method],
        path: url,
        metadata: {
          collection_url: collection_url,
          method: method,
          user_websocket_token: Webmate.Auth.getToken()
        },
        params: {}
      }
      if (method == 'create' || method == 'update' || method == 'patch')
        packet_data.params = JSON.stringify(options.attrs || model.toJSON(options))

      Webmate.channels['api'].send(url, packet_data, methodMap[method])
      model.trigger "request", model
