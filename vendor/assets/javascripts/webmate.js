define('webmate', [
  'require',
  '/assets/webmate/libs/underscore',
  '/assets/webmate/libs/backbone',
  'jquery',
  '/assets/webmate/auth.js',
  '/assets/webmate/client.js',
  '/assets/webmate/backbone_ext/resources',
  '/assets/webmate/backbone_ext/sync.js',
  '/assets/webmate/backbone_ext/nested_views.js'
], function(require, _, Backbone, $, auth, client, resources, sync, nested_views){

  connection_credentials = null
  f_build_client = function(channel){
    var new_client = new client(channel);
    if (connection_credentials) {
      new_client.connect(connection_credentials)
    }
    Webmate.channels[channel] = new_client;
    return new_client;
  };

  f_connect = function(credentials, callback) {
    connection_credentials = credentials
    for (channel in Webmate.channels) {
      Webmate.channels[channel].connect(credentials)
    }
    // we don't wait connection establish
    // socket.io should supports requests queue
    if (callback) { callback.call() };
    return true;
  };

  f_prepare_connections = function(){
    for (index in arguments){
      channel_name = arguments[index]
      f_build_client(channel_name)
    }
  }

  this.Webmate = {
    channels: {},
    websocketsEnabled: true,
    Auth: require('/assets/webmate/auth.js'),
    Client: require('/assets/webmate/client.js'),
    buildClient: f_build_client,
    connect: f_connect,
    prepareConnections: f_prepare_connections
  }

  return this.Webmate
})
