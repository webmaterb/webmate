# support nested views -> 
#   propagate events down to tree,
#   remove objects if upper element has been removed
#
# update Backbone.View: 
#   addChildView(view1, view2..)
#   removeChildView(view2, view3)
#   notifyChilds(event_name, data)
#
#   usage
#     initialize:
#       subview = new ChildView()
#       @addChildView(subview)
#
#     render:
#       $(dom).insert($el)
#       @notifyChilds('rendered')
#
define [
  '/assets/webmate/libs/underscore.js',
  '/assets/webmate/libs/backbone.js'
], (underscore, backbone) ->
  _.extend(Backbone.View.prototype, {
    addChildView: () ->
      @childViews or={}
      # lazy instantiation required, else it would class-global var
      for view in arguments
        if view instanceof Backbone.View
          @childViews[view.cid] = view
      return arguments

    removeChildView: (view_or_views) ->
      @childViews or={}
      for view in arguments
        if view instanceof Backbone.View
          delete @childViews[view.cid]

    notifyChilds: (event_name) ->
      @childViews or= {}
      return false unless event_name?

      @trigger.apply(this, arguments)
      for cid of @childViews
        view = @childViews[cid]
        view.notifyChilds.apply(view, arguments)
      return true
  })

  Backbone.View::remove = _.wrap(Backbone.View::remove, (origin_remove) ->
    @childViews or= {}
    for cid of @childViews
      @remove.apply(@childViews[cid])
    origin_remove.call(this)
  )

  return Backbone.View
