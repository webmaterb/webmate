define [
  '/assets/webmate/libs/underscore.js',
  '/assets/webmate/libs/backbone.js'
], (underscore, backbone) ->

  # extend model
  _.extend(Backbone.Model.prototype, {
    idAttribute: 'id'
    resourceName: () -> @collection.resourceName()
    collectionName: () -> @collection.collectionName()
    channel: () -> _.result(@collection, 'channel')
  })

  # extend collection
  _.extend(Backbone.Collection.prototype, {
    resourceName: () -> @resource
    collectionName: () -> "#{@resource}s"

    bindSocketEvents: () ->
      return false if not @channel?
      collection  = @

      # note: possible, this should be in webmate
      client = Webmate.channels[@channel]
      client or= Webmate.buildClient(@channel)

      path = _.result(@, 'url')

      client.on "#{path}/read", (response, params) =>
        if collection.reset(collection.parse(response))
          collection.trigger('sync', collection, response, {})
          collection.trigger('reset', collection, response, {})

      client.on "#{path}/create", (response, params) =>
        if collection.add(collection.parse(response))
          collection.trigger('add', collection, response, {})

      client.on "#{path}/update", (response, params) =>
        if collection.add(collection.parse(response), { merge: true })
          collection.trigger('change', collection, response, {})

      client.on "#{path}/delete", (response, params) =>
        if collection.remove(collection.parse(response))
          collection.trigger('change', collection, response, {})
  })

  # alias method chain
  # this is way to pass additional data to model
  # possible, obsoleted code
  Backbone.Collection::_prepareModelWithoutAssociations = Backbone.Collection::_prepareModel
  Backbone.Collection::_prepareModel = (attrs, options) ->
    attrs = _.extend(attrs, @sync_data) if @sync_data
    @._prepareModelWithoutAssociations(attrs, options)
