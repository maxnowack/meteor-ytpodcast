@YoutubeVideo = class YoutubeVideo
  constructor: (id, callback) ->
    video_info = HTTP.get "http://www.youtube.com/get_video_info?video_id=#{id}"
    video = @decodeQueryString video_info.content

    return video if video.status is "fail"
    video.sources = @decodeStreamMap video.url_encoded_fmt_stream_map
    video.getSource = (type, quality) ->
      lowest = null
      exact = null
      for key, source of @sources when source.type.match type
        if source.quality.match quality
          exact = source
        else
          lowest = source
      return exact || lowest

    return video

  decodeQueryString: (queryString) ->
    r = {}
    keyValPairs = queryString.split "&"
    for keyValPair in keyValPairs
      key = decodeURIComponent keyValPair.split("=")[0]
      val = decodeURIComponent keyValPair.split("=")[1] || ""
      r[key] = val
    return r

  decodeStreamMap: (url_encoded_fmt_stream_map) ->
    sources = {}
    for urlEncodedStream in url_encoded_fmt_stream_map.split(",")
      stream = @decodeQueryString urlEncodedStream
      type    = stream.type.split(";")[0]
      quality = stream.quality.split(",")[0]
      stream.original_url = stream.url
      stream.url = "#{stream.url}&signature=#{stream.sig}"
      sources["#{type} #{quality}"] = stream
    return sources
