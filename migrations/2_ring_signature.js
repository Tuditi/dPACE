const Signature = artifacts.require("Signature");

module.exports = function(deployer) {
  deployer.deploy(Signature);
};
