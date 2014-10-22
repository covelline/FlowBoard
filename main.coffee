$ ->
  comments = []

  minTime = 0
  maxTime = 0

  # コメント表示時間
  showTime = 10000
  offsetX = $("#display").width()

  # 再生
  playing = false
  interval = 33
  setInterval ->
    if playing
      setSliderTime getSliderTime() + interval
  , interval

  updateTime = ->
    currentTimeStr = formatTimeStamp getSliderTime()
    $("#time").text currentTimeStr

  getSliderTime = -> parseInt($("#slider").val())

  updateCommentPosition = ->
    for elm in $("#display .comment")
      jelm = $(elm)
      createdAt = parseInt jelm.attr("fb-createdAt")
      continue unless createdAt
      current = getSliderTime()
      # ちょうど投稿した時間に画面右端、showTime 経過したら画面左端に消える位置
      width = $("#display").width() - jelm.width()
      x = width * (createdAt - current) / showTime + offsetX
      jelm.css "left", x

  formatTimeStamp = (timestamp) ->
    date = new Date(timestamp)
    "#{date.getFullYear()}-#{date.getMonth() + 1}-#{date.getDate()} #{date.getHours()}-#{date.getMinutes()}-#{date.getSeconds()}"

  addComment = (comment) ->
    comments.push comment

    first = true
    for comment in comments
      if comment.createdAt
        if first
          minTime = comment.createdAt
          maxTime = comment.createdAt
          first = false
        else
          minTime = Math.min(comment.createdAt, minTime)
          maxTime = Math.max(comment.createdAt, minTime)

    $("#slider").attr "min", minTime - 10000
    $("#slider").attr "max", maxTime

  showComments = (startAt, endAt) ->
    # TODO: 全部消さないで範囲内のは残す
    $("#display").html ""

    for comment in comments
      # TODO: 時間が範囲内か調べる
      $("#display").append $ """
        <div class="comment" fb-createdAt="#{comment.createdAt}">
          #{comment.text}
        </div>
      """

  firstLoad = true

  commentsRef = new Firebase("https://flowboard.firebaseio.com/comments")
  commentsRef.on "child_added", (snapshot) ->
    
    # add name as id
    comment = $.extend snapshot.val(), 
      id: snapshot.name()

    addComment comment

    showComments()

    if firstLoad
      firstLoad = false
      setSliderTime Date.now()
      playing = true

  $("#submit-button").click sendComment
  $("#text-input").keypress (e) ->
    sendComment() if e.which is 13
    true

  sendComment = ->
    commentsRef.push
      text: $("#text-input").val()
      createdAt: Firebase.ServerValue.TIMESTAMP

    $("#text-input").val ""

    setSliderTime Date.now()
    playing = true

  $("#slider").on "input", ->
    playing = false
    updateTime()
    updateCommentPosition()

  setSliderTime = (time) ->
    max = $("#slider").attr "max"
    $("#slider").attr "max", Math.max max, time

    $("#slider").val time

    updateTime()
    updateCommentPosition()

  $("#play-button").click ->
    playing = !playing
