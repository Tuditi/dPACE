/*const EthCrypto = require('eth-crypto');
const identityRSP = EthCrypto.createIdentity();
const fs = require ('fs');

const Audi_privKey = '6bc48fee787b0809c3e8fe3fe854e9319ff2d50fbbe5f6d5f1dc3c2602d56ac4';

fs.writeFile('LargeInt.txt', parseInt(Audi_privKey,16), (err) =>{
    if (err) throw err;
});*/

const Web3 = require('web3');
const web3 = new Web3();

const zkp = ['0x185a2885dbc163bb2fdf4e4c361419eba3d3cc0e7f3f76a1e51bcdcd43dde6f4', '0x2eee74f45e9841a6add22b08939b366d23ac065937fd9206d12dba6bf5b6cf11', '0x2d39844fd1355dd6d210cf85bcfd9a9abf2083cd0b2d351b17de7fa5200c5a81', '0x2e28bc6c59b29e5786af366e87096edb50c92a3bf681f39dd2520f4d83c34115', '0x0a969b436dbd7f35f6858641e3747c2e27b197cb62b2ca6725a8ca0b3152d877', '0x1aa833e4e762b97c004480ce1b4e30b37e14dc82dc31df333ae0adc5774153f5', '0x0e24e11bee213d0b09c579452a6c0ac61ca20ea07eeeecfa15617350ec725537', '0x200727e6ebc7dc9c0f77bd0981fe6b9d7d819c4172f046409643978765bd7366']
var integer = new Array();

zkp.forEach( (element)=> integer.push(web3.utils.hexToNumberString(element)));
console.log(integer);
console.log(web3.utils.toHex('1000000000000000000'))
//console.dir(identityRSP);
//console.dir(identityRSP.privateKey.slice(2));