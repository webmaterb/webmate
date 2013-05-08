// not async module definition
// deps: ['backbone', 'jquery', 'underscore', 'auth']
(function(){

  webmate = {
    channels: {},
    websocketsEnabled: true
  }

  this.Webmate = webmate

  require(['/assets/webmate/auth.js'],   function(auth){ 
    this.Webmate.Auth = auth
  });

  require(['/assets/webmate/client.js'], function(Client) { 
    /* module exports data to global backbone var*/
  });

  require(['/assets/webmate/backbone_ext/sync.js'], function(Sync) { 
    /* module exports data to global backbone var*/
  });

  require(['/assets/webmate/backbone_ext/resources'], function(Resources) { 
    /* module exports data to global backbone var*/
  })

  this.Webmate

}).call(this);
/*
// join all webmate js to single webmate object
define('webmate',
  [
    'backbone',
    'jquery',
    'underscore',
    'auth',
    'sync'
  ],
  function(Backbone, $, _, auth, sync){
//    console.log(arguments)

    return {
      channels: {},
      webmate_version: 'test',
      Auth: auth
    }
})
*/
