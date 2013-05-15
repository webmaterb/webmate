define [
    'webmate',
    '/assets/webmate/libs/underscore.js',
    '/assets/webmate/libs/socket.io.js'
], (webmate, socket_io) ->

  # use webmate? use config module?
  config = {
    websockets_enabled: true,
    websockets_defaults: {
      host: location.hostname
      port: Webmate.websocketsPort or location.port
    }
  }

  # define 'class'
  client_constructor = (channel_name) ->
    @channel_name = channel_name
    @bindings     = {}
    client_id    = _.uniqueId('client')
    websocket    = null # not yet connected.

    self = this
    publicConnectFunction = (credentials) ->
      credentials or= {}
      websocket = new io.Socket(_.extend({}, config.websockets_defaults, {
        resource: @channel_name
        query: $.param(credentials)
      }))

      websocket.on 'connect', () ->
        client_constructor.connectionEventHandler(channel_name)

      websocket.onPacket = (packet) ->
        return unless packet.type is 'message'
        parsed_packet = client_constructor.parsePacketData(packet.data)
        client_constructor.onPacketHandler.call(self, parsed_packet)

      return websocket

    publicOnFunction = (action, callback) ->
      self.bindings[action] = [] if !self.bindings[action]
      self.bindings[action].push(callback)
      self.bindings

    publicSendFunction = (path, data, method) ->
      return false unless websocket?
      data.path = path
      data.method = method
      packet = {
        type: 'message',
        data: JSON.stringify(data)
      }
      websocket.packet(packet)

    # generate and return new Webmate.Client
    return {
      channel_name:  @channel_name
      on:            publicOnFunction
      send:          publicSendFunction
      connect:       publicConnectFunction
    }

  # assign common functions to constructor itself. class methods
  client_constructor.connectionEventHandler = (channel_name) ->
    console.log("connection for channel '#{channel_name}' established")

  client_constructor.parsePacketData = (packet_data) ->
    data = JSON.parse(packet_data)
    data.response.body = JSON.parse(data.response.body)
    return data

  client_constructor.onPacketHandler = (message) ->
    console.log('packet', message)
    metadata = message.request.metadata
    eventBindings = @bindings["#{metadata.collection_url}/#{metadata.method}"]
    
    _.each eventBindings, (eventBinding) ->
      eventBinding(message.response.body, message.request.metadata)

  # module ending
  # return class Webmate.Client
  return client_constructor
