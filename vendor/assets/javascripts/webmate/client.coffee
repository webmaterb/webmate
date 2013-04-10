class Webmate.Client
  constructor: (channel_name) ->
    self = @
    @bindings = {}
    @channel_name = channel_name

    if @useWebsockets()
      @websocket = @createConnection( (message) ->
        console.log('place for fire')
        metadata = message.request.metadata
        eventBindings = @bindings["#{metadata.collection_url}/#{metadata.method}"]
        
        _.each eventBindings, (eventBinding) ->
          eventBinding(message.response.body, message.request.metadata)
      )
  
  useWebsockets: ->
    window.Webmate.websocketsEnabled isnt false && io && io.Socket

  createConnection: (onMessageHandler) ->
    self = @
    @clientId or= Math.random().toString(36).substr(2)

    socket = new io.Socket
      resource: @channel_name
      host: location.hostname
      port: Webmate.websocketsPort or location.port

    socket.on "connect", () ->
      console.log("connection established")

    socket.onPacket = (packet) ->
      console.log(packet)
      return unless packet.type is 'message'
      parsed_packet = Webmate.Client::parsePacketData(packet.data)
      onMessageHandler.call(self, parsed_packet)

    socket.connect()
    socket

  on: (action, callback) ->
    @bindings[action] = [] if !@bindings[action]
    @bindings[action].push(callback)
    @

  send: (path, data, method) ->
    data.path = path
    data.method = method
    packet = {
      type: 'message',
      data: JSON.stringify(data)
    }
    @websocket.packet(packet)

Webmate.Client::parsePacketData = (packet_data) ->
  data = JSON.parse(packet_data)
  data.response.body = JSON.parse(data.response.body)
  data

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
