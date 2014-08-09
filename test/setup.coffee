chai = require "chai"
chaiChanges = require ".."
chaiAsPromised = require "chai-as-promised"

chai.should()
chai.use chaiChanges
chai.use chaiAsPromised

global.expect = require("chai").expect
global.when = require("when")

