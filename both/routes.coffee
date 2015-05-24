Router.route '/', ->
  @render 'Index'

Router.route '/:type/:id', (->
  feed = new YTPodcast @params.type, @params.id, @params.query
  @response.end feed.getXml()
), where: 'server'
