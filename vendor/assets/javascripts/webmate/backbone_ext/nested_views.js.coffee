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
      # lazy instantiation required, else it would class-global var
      @childViews or= {}
      for view in arguments
        if view instanceof Backbone.View
          @childViews[view.cid] = view
      return arguments

    removeChildView: (view_or_views) ->
      for view in arguments
        if view instanceof Backbone.View
          delete @childViews[view.cid]

    notifyChilds: (event_name) ->
      return false unless event_name?

      @trigger.apply(this, arguments)
      for cid of @childViews
        delete view
        view = @childViews[cid]
        view.notifyChilds.apply(view, arguments)
      return true
  })

  return Backbone.View
