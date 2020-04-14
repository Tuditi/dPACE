const EthCrypto = require('eth-crypto');
const identityRSP = EthCrypto.createIdentity();

console.dir(identityRSP);
console.dir(identityRSP.privateKey.slice(2));