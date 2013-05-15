define [
  '/assets/webmate/libs/underscore.js',
  '/assets/webmate/libs/backbone.js'
], (underscore, backbone) ->
  # NOTE - export value not configured for this absolute path 
  # so backbone var will be not defined.
  # anyway, we update globally exported Backbone
  # the same for underscore
  #
  Backbone.Model::idAttribute = 'id'
  Backbone.Model::resourceName = -> @collection.resourceName()
  Backbone.Model::collectionName = -> @collection.collectionName()
  Backbone.Model::channel = -> _.result(@collection, 'channel')

  Backbone.Collection::resourceName = -> @resource
  Backbone.Collection::collectionName = -> "#{@resource}s"

  Backbone.Collection::bindSocketEvents = () ->
    return false if not @channel?
    collection  = @

    # note: possible, this should be in webmate
    client = Webmate.channels[@channel]
    client or= Webmate.buildClient(@channel)

    path = _.result(@, 'url')

    client.on "#{path}/read", (response, params) =>
      if collection.set(collection.parse(response))
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

  Backbone.Collection::_prepareModelWithoutAssociations = Backbone.Collection::_prepareModel
  Backbone.Collection::_prepareModel = (attrs, options) ->
    attrs = _.extend(attrs, @sync_data) if @sync_data
    @._prepareModelWithoutAssociations(attrs, options)
