const EthCrypto = require('eth-crypto');
const identityRSP = EthCrypto.createIdentity();
const fs = require ('fs');

const Audi_privKey = '6bc48fee787b0809c3e8fe3fe854e9319ff2d50fbbe5f6d5f1dc3c2602d56ac4';

fs.writeFile('LargeInt.txt', parseInt(Audi_privKey,16), (err) =>{
    if (err) throw err;
});
//console.dir(identityRSP);
//console.dir(identityRSP.privateKey.slice(2));