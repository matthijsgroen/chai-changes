#= require ./../chai-changes

describe 'Chai-Changes', ->

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

    describe 'mix and match', ->

      it 'can use from to and by in one sentence', ->
        result = 3
        expect(-> result).to.change.from(3).to(5).by(2).when -> result = 5

