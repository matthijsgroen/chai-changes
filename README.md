chai-changes
============

chai-changes is an extension to the [chai](http://chaijs.com/) assertion library that
provides a set of change-specific assertions.

Usage
-----

Include `chai-changes.js` in your test file, after `chai.js` (version 1.0.0-rc1 or later):

    <script src="chai-changes.js"></script>

Use the assertions with chai's `expect` or `should` assertions.

Assertions
----------

All assertions use a `when` mechanism.


Using 'expect':

    expect(-> codeThatYieldsAChangedResult).to....when ->
      executeTheCodeThatCausesTheChange()

The code within the `expect` section will be executed first, then the
code in the `when` section will be executed and then the code in the
`expect` section will be executed again and the differences will be
asserted.

Same test using 'should':

    (-> codeThatYieldsAChangedResult).should....when ->
      executeTheCodeThatCausesTheChange()

### `change`

Assert if the 'expect/should' changes its outcome when 'when' is
executed

    result = 0
    (-> result).should.change.when -> result += 1
    expect(-> result).to.change.when -> result -= 1
    expect(-> result).not.to.change.when -> result = result * 1

### `change.by(delta)`

Assert if the change of the 'expect/should' has the provided delta

    result = 0
    (-> result).should.change.by(3).when -> result += 3
    expect(-> result).not.to.change.by(-3).when -> result += 1
    expect(-> result).to.change.by(-2).when -> result -= 2

### `change.from(startValue)`

Assert if the change starts from a certain value. The value is
compared using a deep equal.

    result = ['a', 'b']
    (-> result).should.change.from(['a', 'b']).when -> result.push('c')
    (-> result).should.change.from(['a', 'b']).to(['a', 'b', 'c']).when -> result.push('c')

### `change.to(endValue)`

Assert if the change ends in a certain value. The value is
compared using a deep equal.

    result = ['a', 'b']
    (-> result).should.change.to(['a', 'b', 'c']).when -> result.push('c')
    (-> result).should.change.from(['a', 'b']).to(['a', 'c']).when -> result = ['a', 'c']

## License

Copyright (c) 2012 Matthijs Groen

MIT License (see the LICENSE file)
