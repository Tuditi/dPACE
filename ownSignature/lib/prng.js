const XorShift128Plus = require('xorshift.js');
const crypto = require('crypto');

class Prng{
  constructor(){
    this.seed = crypto.randomBytes(16).toString('hex');
    this.prng = new XorShift128Plus.XorShift128Plus(this.seed);
  }

  get random(){
    return this.prng.randomBytes(32).toString('hex');
  }
}

module.exports = Prng