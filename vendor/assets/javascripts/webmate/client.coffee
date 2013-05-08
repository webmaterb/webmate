class Webmate.Client
  constructor: (channel_name) ->
    self = @
    @bindings = {}
    @channel_name = channel_name

    if @useWebsockets()
      @websocket = @createConnection( (message) ->
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

    # pass callback func, if needed be sure what callback exists
    token = Webmate.Auth.getToken()
    return false unless token?

    socket = new io.Socket
      resource: @channel_name
      host: location.hostname
      port: Webmate.websocketsPort or location.port
      query: $.param(token: token)

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
