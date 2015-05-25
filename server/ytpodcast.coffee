authenticated = false
authenticate = ->
  key = Meteor.settings.YOUTUBE_API_TOKEN
  throw new Error "Youtube API key is empty!" unless key?
  YoutubeApi.authenticate
    type: "key"
    key: key
  authenticated = true

YTApi =
  listChannels: Async.wrap YoutubeApi.channels.list
  listPlaylists: Async.wrap YoutubeApi.playlists.list
  getPlaylistItems: Async.wrap YoutubeApi.playlistItems.list
  listVideo: Async.wrap YoutubeApi.videos.list

@YTPodcast = class YTPodcast
  constructor: (@type, @id, @options) ->
    authenticate() unless authenticated

    @format = @options?.format or 'video/mp4'
    @quality = @options?.quality or 'hd720'

    switch @type
      when 'channel'
        channel = YTApi.listChannels part: 'contentDetails, snippet', id: @id
        @data = channel.items[0]
        @playlistId = @data.contentDetails.relatedPlaylists.uploads

        @title = @data.snippet.title
        @description = @data.snippet.description
        @author = @title
        @image = @data.snippet.thumbnails.high.url
      when 'playlist'
        playlist = YTApi.listPlaylists part: 'snippet', id: @id
        @data = playlist.items[0]
        @playlistId = @data.id

        @title = @data.snippet.title
        @description = @data.snippet.description
        @author = @data.snippet.channelTitle
        @image = @data.snippet.thumbnails.high.url

    playlistItems = @getAllPlaylistItems()

    playlistItems.forEach (item, index, arr) ->
      details = YTApi.listVideo
        part: 'contentDetails'
        id: item.snippet.resourceId.videoId
      return arr.splice index, 1 unless details.items.length > 0
      item.contentDetails = details.items[0].contentDetails

    @data.items = playlistItems

  getAllPlaylistItems: ->
    items = []
    response = YTApi.getPlaylistItems
      part: 'snippet'
      playlistId: @playlistId
      maxResults: 50

    items = items.concat response.items

    while response.nextPageToken
      response = YTApi.getPlaylistItems
        part: 'snippet'
        playlistId: @playlistId
        maxResults: 50
        pageToken: response.nextPageToken
      items = items.concat response.items

    return items



  getFeed: ->
    feed = new Podcast
      title: @title
      description: @description
      author: @author
      generator: 'YTPodcast Meteor Generator 1.0.0'
      itunesAuthor: @author
      itunesSummary: @description
      image_url: @image
      itunesImage: @image

    @data.items.forEach (item) =>
      videoId = item.snippet.resourceId.videoId

      duration = moment.isoDuration item.contentDetails.duration if item.contentDetails?
      feed.item
        title: item.snippet.title
        description: item.snippet.description
        url: "https://www.youtube.com/watch?v=#{videoId}"
        guid: item.id
        author: item.snippet.channelTitle
        date: item.snippet.publishedAt
        itunesImage: item.snippet.thumbnails?.high?.url
        itunesDuration: duration?.format()
        enclosure:
          url: @videoUrl videoId
          mime: @format
    return feed

  videoUrl: (id) ->
    Meteor.absoluteUrl "video/#{id}?format=#{encodeURIComponent @format}&quality=#{encodeURIComponent @quality}"

  getXml: ->
    @getFeed().xml()
