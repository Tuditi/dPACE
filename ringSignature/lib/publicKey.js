const Web3 = require('web3');
const web3 = new Web3();

class PublicKey{
    constructor(point,hasher){
      this.point = point;
      this.hasher = hasher;
    }
    
    compress(){
      let pointX = this.point.x;
      let mask = web3.utils.toBN('0x8000000000000000000000000000000000000000000000000000000000000000');
      if(this.point.y.umod(web3.utils.toBN(2))==0){
        //Do Nothing;
      } else if (this.point.y.umod(web3.utils.toBN(2))==1){
        pointX = pointX.add(mask);
      } else{
        throw "Modulo of Big Number wasn't correctly calculated";
      }   
      return pointX;
    }
  }
  
  module.exports = PublicKey;