const Web3 = require('web3');
const web3 = new Web3();
class PublicKey{
    constructor(point,hasher){
      this.point = point;
      this.hasher = hasher;
    }
    
    compress(){
      let pointX = this.point.x.toString(16);
      let prefix;
      if(this.point.y.umod(web3.utils.toBN(2))==0){
        prefix = '0x02';
      } else if (this.point.y.umod(web3.utils.toBN(2))==1){
        prefix = '0x03';
      } else{
        throw "Modulo of Big Number wasn't correctly calculated";
      }    
      return prefix.concat(pointX)
    }
  }
  
  module.exports = PublicKey;