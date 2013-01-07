
((chaiChanges) ->
  # Module systems magic dance.
  if (typeof require == "function" && typeof exports == "object" && typeof module == "object")
    # NodeJS
    module.exports = chaiChanges
  else if (typeof define == "function" && define.amd)
    # AMD
    define -> chaiChanges
  else
    # Other environment (usually <script> tag): plug in to global chai instance directly.
    chai.use chaiChanges
)((chai, utils) ->
  inspect = utils.inspect
  flag = utils.flag

  ###
  #
  # Changes Matchers
  #
  ###

  chai.Assertion.addMethod 'when', (val, options = {}) ->
    definedActions = flag(this, 'whenActions') || []
    object = flag(this, 'object')
    flag(this, 'whenObject', object)

    action.before?(this) for action in definedActions
    # execute the 'when'
    result = val()
    flag(this, 'object', result)

    if result.then?
      done = options?.notify
      done ?= ->
      # promise
      promiseCallback = =>
        try
          action.after?(this) for action in definedActions
          done()
        catch error
          done new Error error
          throw new Error error
      result.then promiseCallback, promiseCallback
    else
      action.after?(this) for action in definedActions
    this

  noChangeAssert = (context) ->
    relevant = flag(context, 'no-change')
    return unless relevant

    negate = flag(context, 'negate')
    flag(context, 'negate', @negate)
    object = flag(context, 'whenObject')

    startValue = flag(context, 'changeStart')
    endValue = object()

    result = !utils.eql(endValue, startValue)
    context.assert result,
      "expected `#{formatFunction object}` to change, but it stayed #{utils.inspect startValue}",
      "expected `#{formatFunction object}` not to change, but it changed from #{utils.inspect startValue} to #{utils.inspect endValue}",
    flag(context, 'negate', negate)

  changeByAssert = (context) ->
    negate = flag(context, 'negate')
    flag(context, 'negate', @negate)
    object = flag(context, 'whenObject')

    startValue = flag(context, 'changeStart')
    endValue = object()
    actualDelta = endValue - startValue

    context.assert (@expectedDelta is actualDelta),
      "expected `#{formatFunction object}` to change by #{@expectedDelta}, but it changed by #{actualDelta}",
      "expected `#{formatFunction object}` not to change by #{@expectedDelta}, but it did"
    flag(context, 'negate', negate)

  changeToBeginAssert = (context) ->
    negate = flag(context, 'negate')
    flag(context, 'negate', @negate)
    object = flag(context, 'whenObject')

    startValue = object()

    result = !utils.eql(startValue, @expectedEndValue)
    result = !result if negate
    context.assert result,
      "expected `#{formatFunction object}` to change to #{utils.inspect @expectedEndValue}, but it was already #{utils.inspect startValue}",
      "not supported"
    flag(context, 'negate', negate)

  changeToAssert = (context) ->
    negate = flag(context, 'negate')
    flag(context, 'negate', @negate)
    object = flag(context, 'whenObject')

    endValue = object()

    result = utils.eql(endValue, @expectedEndValue)
    context.assert result,
      "expected `#{formatFunction object}` to change to #{utils.inspect @expectedEndValue}, but it changed to #{utils.inspect endValue}",
      "expected `#{formatFunction object}` not to change to #{utils.inspect @expectedEndValue}, but it did"
    flag(context, 'negate', negate)

  changeFromBeginAssert = (context) ->
    negate = flag(context, 'negate')
    flag(context, 'negate', @negate)
    object = flag(context, 'whenObject')

    startValue = object()

    result = utils.eql(startValue, @expectedStartValue)
    context.assert result,
      "expected the change of `#{formatFunction object}` to start from #{utils.inspect @expectedStartValue}, but it started from #{utils.inspect startValue}",
      "expected the change of `#{formatFunction object}` not to start from #{utils.inspect @expectedStartValue}, but it did",
    flag(context, 'negate', negate)

  changeFromAssert = (context) ->
    negate = flag(context, 'negate')
    flag(context, 'negate', @negate)
    object = flag(context, 'whenObject')

    startValue = flag(context, 'changeStart')
    endValue = object()

    result = !utils.eql(startValue, endValue)
    result = !result if negate
    context.assert result,
      "expected `#{formatFunction object}` to change from #{utils.inspect @expectedStartValue}, but it did not change"
      "not supported"
    flag(context, 'negate', negate)

  # Verifies if the subject return value changes by given delta 'when' events happen
  #
  # Examples:
  #   (-> resultValue).should.change.by(1).when -> resultValue += 1
  #
  chai.Assertion.addProperty 'change', ->
    flag(this, 'no-change', true)

    definedActions = flag(this, 'whenActions') || []
    # Add a around filter to the when actions
    definedActions.push
      negate: flag(this, 'negate')

      # set up the callback to trigger
      before: (context) ->
        startValue = flag(context, 'whenObject')()
        flag(context, 'changeStart', startValue)
      after: noChangeAssert

    flag(this, 'whenActions', definedActions)

  formatFunction = (func) ->
    func.toString().replace(/^\s*function \(\) {\s*/, '').replace(/\s+}$/, '').replace(/\s*return\s*/, '')

  changeBy = (delta) ->
    flag(this, 'no-change', false)
    definedActions = flag(this, 'whenActions') || []
    # Add a around filter to the when actions
    definedActions.push
      negate: flag(this, 'negate')
      expectedDelta: delta
      after: changeByAssert
    flag(this, 'whenActions', definedActions)

  chai.Assertion.addChainableMethod 'by', changeBy, -> this

  changeTo = (endValue) ->
    flag(this, 'no-change', false)
    definedActions = flag(this, 'whenActions') || []
    # Add a around filter to the when actions
    definedActions.push
      negate: flag(this, 'negate')
      expectedEndValue: endValue
      before: changeToBeginAssert
      after: changeToAssert
    flag(this, 'whenActions', definedActions)

  chai.Assertion.addChainableMethod 'to', changeTo, -> this

  changeFrom = (startValue) ->
    flag(this, 'no-change', false)
    definedActions = flag(this, 'whenActions') || []
    # Add a around filter to the when actions
    definedActions.push
      negate: flag(this, 'negate')
      expectedStartValue: startValue
      before: changeFromBeginAssert
      after: changeFromAssert
    flag(this, 'whenActions', definedActions)

  chai.Assertion.addChainableMethod 'from', changeFrom, -> this

)

