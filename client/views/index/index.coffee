getFeed = (form) ->
  link = getLinkType(form.link.value)
  if link.type == 'none'
    alert 'this is not a valid link!'
    false
  else
    location.href = "/#{link.type}/#{link.data}/?format=#{link.format}"
    true

getLinkType = (link) ->
  channelMatch = link.match(/youtube\.com\/(?:channel|user)\/([a-zA-Z0-9\-_]+)/)
  playlistMatch = link.match(/youtube\.com\/playlist\?list=([a-zA-Z0-9\-_]+)/)
  if channelMatch
    type: 'channel'
    data: channelMatch[1]
    format: 'mp4'
  else if playlistMatch
    type: 'playlist'
    data: playlistMatch[1]
    format: 'mp4'
  else
    type: 'none'

Template.Index.events
  'submit #podcastForm': (event) ->
    event.preventDefault()
    getFeed event.target
