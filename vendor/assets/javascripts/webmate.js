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

  f_build_client = function(channel){
    var new_client = new client(channel);
    Webmate.channels[channel] = new_client;
    return new_client;
  };

  f_connect = function(credentials, callback) {
    for (channel in Webmate.channels) {
      Webmate.channels[channel].connect(credentials)
    }
    // we don't wait connection establish
    // socket.io should supports requests queue
    if (callback) { callback.call() };
    return true;
  };

  this.Webmate = {
    channels: {},
    websocketsEnabled: true,
    Auth: require('/assets/webmate/auth.js'),
    Client: require('/assets/webmate/client.js'),
    buildClient: f_build_client,
    connect: f_connect
  }

  return this.Webmate
})
