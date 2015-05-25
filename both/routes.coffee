Router.route '/', ->
  @render 'Index'

Router.route '/video/:id', (->
  videoInfo = new YoutubeVideo @params.id
  format = @params.format or 'video/mp4'
  quality = @params.quality or 'hd720'

  source = videoInfo.getSource format, quality
  @response.writeHead 301, Location: source.url
  @response.end()
), where: 'server'

Router.route '/:type/:id', (->
  feed = new YTPodcast @params.type, @params.id, @params.query
  xml = feed.getXml()

  @response.writeHead 200,
    'Content-Type': 'text/xml; charset=utf-8'
  @response.end xml
), where: 'server'
