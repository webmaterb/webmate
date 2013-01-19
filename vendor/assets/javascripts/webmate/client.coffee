class Webmate.Client
  constructor: (channel, callback) ->
    self = @
    @bindings = {}
    @channel = channel
    @fullPath = "#{location.hostname}:#{Webmate.websocketsPort or location.port}/#{channel}"
    @clientId = Math.random().toString(36).substr(2)
    if window.Webmate.websocketsEnabled isnt false && window.WebSocket
      @websocket = new WebSocket("ws://#{@fullPath}")
      @websocket.onmessage = (e)->
        data = JSON.parse(e.data)
        eventBinding = self.bindings[data.action]
        _.each eventBinding, (binding)->
          binding(data.response, data.params)
      @websocket.onopen = (e)->
        callback()
    else
      if window.Webmate.websocketsEnabled is false
        console.log("Websockets is disabled. Using http.")
      else
        console.log("Websocket not supported. Using http.")
      callback()
    @
  on: (action, callback)->
    @bindings[action] = [] if !@bindings[action]
    @bindings[action].push(callback)
    @
  send: (action, data, method)->
    data = {} if !data
    method = 'get' if !method
    data.action = action
    data.channel = @channel
    data._client_id = @clientId
    if @websocket
      @websocket.send(JSON.stringify(data))
    else
      $.ajax("http://#{@fullPath}/#{action}", type: method).success (data)->
        console.log(data)
    @
  bindDefaultEvents: (connection)->
    self = @
    _.each App.Collections, (collectionClass)->
      obj = new collectionClass()
      return unless obj
      collectionName = obj.collectionName()
      collectionInstance = App[collectionName]
      return unless collectionInstance
      self.on "#{collectionName}/update", (response, params)->
        return unless response._id
        collectionInstance.get(response._id).set(response)
      self.on "#{collectionName}/read", (response, params)->
        collectionInstance.reset(response)
        collectionInstance.trigger "sync", collectionInstance, response
      self.on "#{collectionName}/create", (response, params)->
        unless self.clientId is params._client_id
          collectionInstance.add(response)
        if self.clientId is params._client_id
          collectionInstance.get(params._cid).set(response)

Webmate.connect = (channel, callback)->
  client = new Webmate.Client(channel, callback)
  Webmate.channels[channel] = client
  client.bindDefaultEvents()
  client
