var chai = require("chai");
var chaiChanges = require("..");
var chaiAsPromised = require("chai-as-promised");

chai.should();
chai.use(chaiChanges);
chai.use(chaiAsPromised);
