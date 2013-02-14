
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

  # # Change Matchers
  #
  # All matchers are build around a before and after assertion to verify the change
  # at a specific moment. The structure of each assertion is as follows:
  #
  #     expect(methodThatWillBeInvokedAtStartAndEnd).to.change.when ->
  #       code that will result in a change when method is rerun
  #
  # The `when` statement will run a series of beforeAssertions, then execute
  # the callback of the `when` argument, wait for that execution to finish if it
  # is a promise, and then execute all afterAssertions.
  #
  # the following keywords will register before and after assertions for `when`:
  #
  # * by (verify a delta)
  # * to (verify that a change resulted in provided end value)
  # * from (verify that a change started at provided start value)
  # * change (verify if result changed at all)
  #
  # Other libraries, such as "chai-backbone" register their own matchers to
  # this before and end assertion chain using `when`
  #

  chai.Assertion.addMethod 'when', (val, options = {}) ->
    definedActions = flag(this, 'whenActions') || []
    object = flag(this, 'object')
    flag(this, 'whenObject', object)

    # Execute all before assertions
    action.before?(this) for action in definedActions

    # execute the 'when'
    result = val()

    isPromise = (typeof result is 'object') && (typeof result.then is 'function')
    if isPromise
      # if the result is a promise, wait till it reached the end state (rejection/fulfillment)
      # before running the after assertions.
      #
      # This will make the `when` method into a promise as well,
      # that will be fulfilled when all assertions pass, and reject if an assertion
      # fails.
      #
      # You can pass in a `{ notify: done }` option hash to wire this
      # async behaviour to your test runner. (e.g. mocha)
      #
      # Because the `when` method will return a promise now, this mechanism
      # works greate with "mocha-as-promised"
      #
      done = options?.notify
      done ?= ->
      # promise
      promiseCallback = =>
        try
          # Run the after assertions if promise is fulfilled or rejected
          action.after?(this) for action in definedActions
          done()
        catch error
          # notify `done` of the error and reraise to reject the promise
          done error
          throw error
      newPromise = result.then promiseCallback, promiseCallback

      # add Promise to current Assertion chain. Mocha-as-promised can pick this up
      return newPromise
    else
      # Run all after assertions for the synchronous code.
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

  # # Increase
  #
  # Assert increase in value. the value must be a numeric
  #
  chai.Assertion.addProperty 'increase', ->
    definedActions = flag(this, 'whenActions') || []
    # Add a around filter to the when actions
    definedActions.push
      negate: flag(this, 'negate')

      # set up the callback to trigger
      before: (context) ->
        startValue = flag(context, 'whenObject')()
        flag(context, 'increaseStart', startValue)

      after: (context) ->
        object = flag(context, 'whenObject')
        endValue = object()
        startValue = flag(context, 'increaseStart')

        negate = flag(context, 'negate')
        flag(context, 'negate', @negate)

        unless negate
          context.assert (startValue != endValue),
            "expected `#{formatFunction object}` to increase, but it did not change"
            "not supported"

        context.assert (startValue < endValue),
          "expected `#{formatFunction object}` to increase, but it decreased by #{startValue - endValue}",
          "expected `#{formatFunction object}` not to increase, but it increased by #{endValue - startValue}"
        flag(context, 'negate', negate)

    flag(this, 'whenActions', definedActions)

  # # Decrease
  #
  # Assert decrease in value. the value must be a numeric
  #
  chai.Assertion.addProperty 'decrease', ->
    definedActions = flag(this, 'whenActions') || []
    # Add a around filter to the when actions
    definedActions.push
      negate: flag(this, 'negate')

      # set up the callback to trigger
      before: (context) ->
        startValue = flag(context, 'whenObject')()
        flag(context, 'decreaseStart', startValue)

      after: (context) ->
        object = flag(context, 'whenObject')
        endValue = object()
        startValue = flag(context, 'decreaseStart')

        negate = flag(context, 'negate')
        flag(context, 'negate', @negate)

        unless negate
          context.assert (startValue != endValue),
            "expected `#{formatFunction object}` to decrease, but it did not change"
            "not supported"

        context.assert (startValue > endValue),
          "expected `#{formatFunction object}` to decrease, but it increased by #{endValue - startValue}",
          "expected `#{formatFunction object}` not to decrease, but it decreased by #{startValue - endValue}"
        flag(context, 'negate', negate)

    flag(this, 'whenActions', definedActions)

  # # atLeast
  #
  # Assert minimal change in value
  #
  byAtLeast = (amount) ->
    definedActions = flag(this, 'whenActions') || []
    # Add a around filter to the when actions
    definedActions.push
      negate: flag(this, 'negate')

      # set up the callback to trigger
      before: (context) ->
        startValue = flag(context, 'whenObject')()
        flag(context, 'atLeastStart', startValue)

      after: (context) ->
        object = flag(context, 'whenObject')
        endValue = object()
        startValue = flag(context, 'atLeastStart')

        negate = flag(context, 'negate')
        flag(context, 'negate', @negate)

        difference = Math.abs(endValue - startValue)

        context.assert (difference >= amount),
          "expected `#{formatFunction object}` to change by at least #{amount}, but changed by #{difference}"
          "not supported"
        flag(context, 'negate', negate)

    flag(this, 'whenActions', definedActions)

  chai.Assertion.addChainableMethod 'atLeast', byAtLeast, -> this

  # # atMost
  #
  # Assert maximum change in value
  #
  byAtMost = (amount) ->
    definedActions = flag(this, 'whenActions') || []
    # Add a around filter to the when actions
    definedActions.push
      negate: flag(this, 'negate')

      # set up the callback to trigger
      before: (context) ->
        startValue = flag(context, 'whenObject')()
        flag(context, 'atMostStart', startValue)

      after: (context) ->
        object = flag(context, 'whenObject')
        endValue = object()
        startValue = flag(context, 'atMostStart')

        negate = flag(context, 'negate')
        flag(context, 'negate', @negate)

        difference = Math.abs(endValue - startValue)

        context.assert (difference <= amount),
          "expected `#{formatFunction object}` to change by at most #{amount}, but changed by #{difference}"
          "not supported"
        flag(context, 'negate', negate)

    flag(this, 'whenActions', definedActions)

  chai.Assertion.addChainableMethod 'atMost', byAtMost, -> this

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

