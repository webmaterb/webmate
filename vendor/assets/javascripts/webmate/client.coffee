class Webmate.Client
  constructor: (channel_name) ->
    self = @
    @bindings = {}
    @channel_name = channel_name

    if @useWebsockets()
      @websocket = @createConnection( (message) ->
        #console.log("message successfully received")
        console.log(message)
        eventBindings = @bindings["#{message.resource}/#{message.action}"]
        _.each eventBindings, (binding)->
          binding(message.response, message.params)
      )
    #else
    #   handle case when we don't have sockets.. stop. we should use socket.io anyway
  
  useWebsockets: ->
    window.Webmate.websocketsEnabled isnt false && io && io.Socket

  createConnection: (onMessageHandler) ->
    self = @

    socket = new io.Socket
      resource: @channel_name
      host: location.hostname
      port: Webmate.websocketsPort or location.port

    socket.on "connect", (data) ->
      console.log("connection established")
      console.log(data)

    socket.onPacket = (packet) ->
      return unless packet.type is 'message'
      data = JSON.parse(packet.data)
      onMessageHandler.call(self, data)

    socket.connect()
    socket

  on: (action, callback) ->
    @bindings[action] = [] if !@bindings[action]
    @bindings[action].push(callback)
    @

  send: (path, data, method) ->
    data.resource = path.split('/')[0]
    data.action   = path.split('/')[1]

    if @useWebsockets()
      @websocket.packet({ type: 'message', data: JSON.stringify(data)})
    else
      # write here something, please
      #$.ajax("http://#{@fullPath}/#{action}", type: method).success (data) ->

Webmate.connect = (channel, callback)->
  client = new Webmate.Client(channel, callback)
  Webmate.channels[channel] = client
  client

  ###
class Webmate.Client
  getFullPath: ->
    "#{location.hostname}:#{Webmate.websocketsPort or location.port}/#{@channel}"

  getClientId: ->
    @clientId or= Math.random().toString(36).substr(2)

  buildSocket: (onMessageHandler) ->

  constructor: (channel, callback) ->
    self = @
    @bindings = {}
    @channel = channel

    if window.Webmate.websocketsEnabled isnt false && window.WebSocket
      @websocket = buildSocket( (message) ->
      )

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
  ###
