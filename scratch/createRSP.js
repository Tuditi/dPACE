/*const EthCrypto = require('eth-crypto');
const identityRSP = EthCrypto.createIdentity();
const fs = require ('fs');

const Audi_privKey = '6bc48fee787b0809c3e8fe3fe854e9319ff2d50fbbe5f6d5f1dc3c2602d56ac4';

fs.writeFile('LargeInt.txt', parseInt(Audi_privKey,16), (err) =>{
    if (err) throw err;
});*/

const Web3 = require('web3');
const web3 = new Web3();

console.dir(web3.utils.hexToNumberString(web3.utils.soliditySha3("0x2b83d0dda242972405243158d42777c18ceef580f5fd7ea754e6a2430864d3a1")));