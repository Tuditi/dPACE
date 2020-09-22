const XorShift128Plus = require('xorshift.js');
const crypto = require('crypto');
const Hasher = require('./hasher.js');
const Web3 = require('web3');

const hasher = new Hasher;
const web3 = new Web3;

class Prng{
  constructor(){
    this.seed = crypto.randomBytes(16).toString('hex');
    this.prng = new XorShift128Plus.XorShift128Plus(this.seed);
  }
  //Private key is in ]0,n[, where n is the order of the elliptic curve
  get random(){
    let value = web3.utils.toBN(this.prng.randomBytes(32).toString('hex')).mod(hasher.l);
    return web3.utils.toHex(value).slice(2);
  }
}

module.exports = Prng