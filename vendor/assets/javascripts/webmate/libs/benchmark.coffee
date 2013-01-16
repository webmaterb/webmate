window.benchmark = (method, iterations, args, context) ->
  time = 0
  timer = (action) ->
    d = +(new Date)
    if time < 1 or action is "start"
      time = d
      0
    else if action is "stop"
      t = d - time
      time = 0
      t
    else
      d - time

  result = []
  i = 0
  timer "start"
  context = window if !context
  while i < iterations
    result.push method.apply(context, args)
    i++
  execTime = timer("stop")
  if typeof console is "object"
    console.log "Mean execution time was: ", execTime / iterations
    console.log "Sum execution time was: ", execTime
    console.log "Result of the method call was:", result[0]
  execTime