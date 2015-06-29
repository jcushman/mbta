$ ->

  ### helpers ###

  $body = $("body")

  apiRequest = (endpoint, query={})->
    query.format = "json"
    return $.ajax(url: "php/api_reflector.php", data: {endpoint:endpoint, query:$.param(query)})

  ### views ###

  showTimetables = ->
    $body.html("")
    stops = params.stops.split(",")
    times = params.times.split(",")
    routes = params.routes.split(",")
    stops = ({id:stop, time:times[i], route:routes[i]} for stop, i in stops)
    bodyFontSize = 2  #ems
    setBodyFontSize = -> $body.css('font-size', "#{bodyFontSize}em")

    updateStops = ()->
      console.log stops
      requests = (apiRequest("predictionsbystop", {stop: stop.id}) for stop in stops)
      $.when.apply($, requests).done((responses...)->
        if stops.length == 1 then responses = [responses]
        html = "<table>"
        for response, i in responses
          [data, responseStatus, responseObject] = response
          responseAge = requests[i].getResponseHeader('Age')
          stop = stops[i]
          mode = data.mode[0]
          route = mode.route.filter((r)->r.route_id==stop.route)[0]
          html += "<tr class='header'><td colspan='2'>#{data.stop_name} #{route.route_name or ""} #{mode.mode_name} <div class='subhead'>(#{stop.time} minutes' walk)</div></td></tr>"

          if route
            trips = route.direction[0].trip
            trips.sort (a,b)->a.pre_away-b.pre_away
            primaryTripIndex = -1
            for trip, i in trips
              # arrivalTime = new Date(trip.pre_dt*1000)
              # arrivalTimeString = ((arrivalTime.getHours() + 11) % 12 + 1) + ":" + ("0"+arrivalTime.getMinutes()).slice(-2)
              trip.minutes = Math.floor((trip.pre_away-responseAge)/60)-stop.time
              primaryTrip = false
              if trip.minutes > 0 and primaryTripIndex < 0
                primaryTripIndex = i
                trip.primary = true
            firstDisplayIndex = Math.max(primaryTripIndex-1, 0)
            trips = trips.slice(firstDisplayIndex,firstDisplayIndex+4)
            for trip, i in trips
              html += """<tr class='#{if trip.primary then "primary" else ""}'>
                            <td>#{trip.trip_headsign}</td>
                            <td><div class='small'>Leave here in</div>#{trip.minutes}&nbsp;min.</td>
                         </tr>"""

          else
            html += "<tr><td>No predictions available</td><td></td></tr>"

        $body.html(html)

        while $body.offset().top + $body.height() < $(window).height() and $(window).width() >= $('table').width()
          bodyFontSize += .1
          setBodyFontSize()

        bodyFontSize -= .1
        setBodyFontSize()

      )

    for stop in stops
      setInterval(updateStops, 1000*60)
      updateStops()

  showRoutes = ->
    $body.html("""
      <div id='chooser'>
        <h1>Choose routes</h1>
        <form onsubmit="return false">
          <div id='routes'></div>
          <!--<div>Choose stop: <select name='stop' id='stop'></select></div>
          <div>Travel time: <input type='text' name='travel-time' value="0" id='travel-time'> minutes <span class="help-text">How long does it take you to walk to this stop?</span></div>-->
          <div><input type='submit' value='View upcoming trips' id='submit-button'></div>
        </form>
      </div>
    """)

    apiRequest(
      "routes"
    ).done((data)->
      console.log data
      html = ""
      for mode in data.mode
        html += "<div>#{mode.mode_name}</div><div class='route-list'>"
        for route in mode.route
          html += "<li class='route'><a href='#' data-routeId='#{route.route_id}'>#{route.route_name}</a></li>"
        html += "</div>"
      $('#routes').html(html)
    )

    $body.on("click", ".route a", ()->
      console.log "clicked!"
      routeLink = $(@)
      routeId = routeLink.attr('data-routeId')
      apiRequest(
        "stopsbyroute", {route: routeId}
      ).done((data)->
        console.log data
        html = "<div class='stops'>"
        for direction in data.direction
          html += "<div class='direction'>#{direction.direction_name}</div>"
          for stop in direction.stop
            html += """<div>
                        <input type='checkbox' name='stops' value='#{stop.stop_id}' data-routeId='#{routeId}'>
                        #{stop.stop_name}:
                        <input type='text' id='minutes_#{stop.stop_id}' value='0' class='stop-minutes'> minutes away
                      </div>"""
        html += "</div>"
        routeLink.after(html)
      )
      false
    )

    $("form").on("submit", ()->
      stops = []
      times = []
      routes = []
      for checkbox in $(':checked')
        stopId = $(checkbox).val()
        stops.push(stopId)
        times.push($('#minutes_'+stopId).val())
        routes.push($(checkbox).attr('data-routeId'))
      document.location = "?stops=#{stops.join(",")}&times=#{times.join(",")}&routes=#{routes.join(",")}"
      false
    )


  ### controller ###

  # parse params

  params = {}
  for v in window.location.search.substring(1).split("&")
    [key, val] = v.split("=")
    params[key] = decodeURIComponent(val)

  # call appropriate view

  if params.stops
    showTimetables()

  else
    showRoutes()