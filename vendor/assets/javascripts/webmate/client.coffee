class Webmate.Client
  constructor: (channel, callback) ->
    self = @
    @bindings = {}
    @channel = channel
    @fullPath = "#{location.hostname}:#{Webmate.websocketsPort or location.port}/#{channel}"
    @clientId = Math.random().toString(36).substr(2)
    if window.Webmate.websocketsEnabled isnt false && window.WebSocket
      @websocket = new WebSocket("ws://#{@fullPath}")
      # prepare queue to store requests if socket not ready
      @callsQueue = new Array()
      @websocket.onmessage = (e) ->
        data = JSON.parse(e.data)
        eventBinding = self.bindings[data.action]
        _.each eventBinding, (binding)->
          binding(data.response, data.params)
      @websocket.onopen = (e) ->
        # process pending queues
        while data = self.callsQueue.pop()
          self.websocket.send(JSON.stringify(data))
        callback() if callback
    else
      if window.Webmate.websocketsEnabled is false
        console.log("Websockets is disabled. Using http.")
      else
        console.log("Websocket not supported. Using http.")
      callback() if callback
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
      if @websocket.readyState == @websocket.OPEN
        @websocket.send(JSON.stringify(data))
      else
        @callsQueue.push(data)
    else
      $.ajax("http://#{@fullPath}/#{action}", type: method).success (data) ->
        console.log(data)
    @

Webmate.connect = (channel, callback)->
  client = new Webmate.Client(channel, callback)
  Webmate.channels[channel] = client
  client
