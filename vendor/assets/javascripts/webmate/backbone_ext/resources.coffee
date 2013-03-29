Backbone.Model::idAttribute = '_id'
Backbone.Model::resourceName = -> @collection.resourceName()
Backbone.Model::collectionName = -> @collection.collectionName()
Backbone.Model::channel = -> _.result(@collection, 'channel')

Backbone.Collection::resourceName = -> @resource
Backbone.Collection::collectionName = -> "#{@resource}s"

Backbone.Collection::bindSocketEvents = () ->
  return false if not @channel?
  model  = @

  # note: possible, this should be in webmate
  client = Webmate.channels[@channel]
  client or= Webmate.connect(@channel)

  # bind
  client.on "#{@collectionName()}/update", (response, params) =>
    return unless response._id
    @get(response._id).set(response)

  client.on "#{@collectionName()}/read", (response, params)->
    model.reset(response)
    model.trigger "sync", model, response

  client.on "#{@collectionName()}/create", (response, params)->
    model.add(response)
    #model.get(response._id).trigger 'sync', response
    #if clientId is params._client_id
    #  model.add(response)
    #else
    #  model.get(params._cid).set(response)

# update existing functions

Backbone.Collection::_prepareModelWithoutAssociations = Backbone.Collection::_prepareModel
Backbone.Collection::_prepareModel = (attrs, options) ->
  attrs = _.extend(attrs, @sync_data) if @sync_data
  @._prepareModelWithoutAssociations(attrs, options)
