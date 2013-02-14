
describe 'Chai-Changes', ->

  describe 'when', ->

    it 'checks conditions after callback execution', ->
      result = 1
      expect(-> result).to.change.when -> result += 1

    it 'changes the object in the assert chain to the callback result', ->
      result = 1
      expect(-> result).not.to.change.when(-> 'hello').and.equal 'hello'

    describe 'with promises', ->

      it 'checks conditions after promise resolved', (done) ->
        result = 1
        def = `when`.defer()
        p = expect(-> result).to.change.when((-> def.promise))
        result += 1
        def.resolve()

        p.should.be.fulfilled.and.notify done

      it 'checks conditions after promise is rejected', (done) ->
        result = 1
        def = `when`.defer()
        p = expect(-> result).to.change.when(-> def.promise)
        result += 1
        def.reject()
        p.should.be.fulfilled.and.notify(done)

      it 'returns a promise about the expectations', (done) ->
        result = 1
        def = `when`.defer()
        p = expect(-> result).to.change.when(-> def.promise)
        p.should.be.broken.with('expected `result;` to change, but it stayed 1').and.notify(done)
        def.resolve()

      it 'accepts a notify option to trigger done()', (done) ->
        result = 1
        def = `when`.defer()
        expect(-> result).to.change.when(
          -> def.promise
          notify: done
        )
        result += 1
        def.resolve()

  describe 'change', ->

    describe 'at all', ->

      it 'detects changes', ->
        result = 1
        expect(->
          expect(-> result).to.change.when -> result = 1
        ).to.throw 'expected `result;` to change, but it stayed 1'
        expect(-> result).to.change.when -> result += 1

      it 'can be negated to not.change', ->
        result = 1
        expect(->
          expect(-> result).not.to.change.when -> result += 2
        ).to.throw 'expected `result;` not to change, but it changed from 1 to 3'
        expect(-> result).to.not.change.when -> 1 + 3
        expect(-> result).to.not.change.when -> undefined

    describe 'by delta', ->

      it 'asserts the delta of a change', ->
        result = 1
        expect(-> result).to.change.by(3).when -> result += 3
        expect(-> result).not.to.change.by(2).when -> result += 3

      it 'reports the contents of the subject method', ->
        result = 1
        expect(->
          (-> 1 + 3; result).should.change.by(3).when -> result += 2
        ).to.throw 'expected `1 + 3;result;` to change by 3, but it changed by 2'

    describe 'to', ->

      it 'asserts end values', ->
        result = ['a']
        expect(-> result).to.change.to(['b']).when -> result = ['b']
        expect(-> result).not.to.change.to(['c']).when -> result = ['b']

      it 'reports the mismatched end value', ->
        result = ['a']
        expect(->
          expect(-> result).to.change.to(['b']).when -> result = ['c']
        ).to.throw 'expected `result;` to change to [ \'b\' ], but it changed to [ \'c\' ]'

      it 'raises an error if there was no change', ->
        result = 'b'
        expect(->
          expect(-> result).to.change.to('b').when -> result = 'b'
        ).to.throw 'expected `result;` to change to \'b\', but it was already \'b\''

    describe 'from', ->

      it 'asserts start values', ->
        result = ['a']
        expect(-> result).to.change.from(['a']).when -> result = ['b']
        expect(-> result).to.change.not.from(['a']).when -> result = ['c']

      it 'reports the mismatched start value', ->
        result = ['a']
        expect(->
          expect(-> result).to.change.from(['b']).when -> result = ['c']
        ).to.throw 'expected the change of `result;` to start from [ \'b\' ], but it started from [ \'a\' ]'

      it 'raises an error if there was no change', ->
        result = 'b'
        expect(->
          expect(-> result).to.change.from('b').when -> result = 'b'
        ).to.throw 'expected `result;` to change from \'b\', but it did not change'

    describe 'increase', ->

      it 'asserts increase in value', ->
        result = 0
        expect(-> result).to.increase.when -> result += 1

        expect(->
          expect(-> result).to.increase.when -> result
        ).to.throw 'expected `result;` to increase, but it did not change'

        expect(->
          expect(-> result).to.increase.when -> result -= 2
        ).to.throw 'expected `result;` to increase, but it decreased by 2'

      it 'asserts no increase in value when negated', ->
        result = 0
        expect(-> result).not.to.increase.when -> result -= 1
        expect(-> result).not.to.increase.when -> result
        expect(->
          expect(-> result).not.to.increase.when -> result += 3
        ).to.throw 'expected `result;` not to increase, but it increased by 3'

    describe 'decrease', ->

      it 'asserts decrease in value', ->
        result = 0
        expect(-> result).to.decrease.when -> result -= 1
        expect(->
          expect(-> result).to.decrease.when -> result
        ).to.throw 'expected `result;` to decrease, but it did not change'
        expect(->
          expect(-> result).to.decrease.when -> result += 4
        ).to.throw 'expected `result;` to decrease, but it increased by 4'

      it 'asserts no increase in value when negated', ->
        result = 0
        expect(-> result).not.to.decrease.when -> result += 1
        expect(-> result).not.to.decrease.when -> result
        expect(->
          expect(-> result).not.to.decrease.when -> result -= 3
        ).to.throw 'expected `result;` not to decrease, but it decreased by 3'

    describe 'mix and match', ->

      it 'can use from to and by in one sentence', ->
        result = 3
        expect(-> result).to.change.from(3).to(5).by(2).when -> result = 5

