const Web3 = require('web3');
const web3 = new Web3();
const Hasher = require('./hasher.js');
const hasher = new Hasher();

class Signature{
    constructor(key_image,c_array,r_array,public_keys){
        this.key_image = key_image;
        this.c_array = c_array;
        this.r_array = r_array;
        this.public_keys = public_keys;
        }

    verify(message){
        let ll_array = [];
        let rr_array = [];
    
        ll_array = this.generate_ll(this.public_keys,this.c_array,this.r_array, hasher);
        rr_array = this.generate_rr(this.public_keys,this.c_array,this.r_array, hasher,this.key_image);
    
        let c_sum = this.c_summation(this.c_array);
        c_sum = c_sum.umod(hasher.l).toString('hex');
    
        const message_digest = hasher.hash_string(message);
        let challenge_arr = [message_digest];
        challenge_arr = challenge_arr.concat(ll_array);
        challenge_arr = challenge_arr.concat(rr_array);
        let challenge = hasher.hash_array(challenge_arr);
        challenge = web3.utils.toBN(challenge,16).toString('hex');
    
        return challenge === c_sum; 
    }

    generate_ll(public_keys,c_array,r_array,hasher){
        let ll_array = [];
        for(let i=0;i<public_keys.length;i++){
            let rG = hasher.G.mul(web3.utils.toBN(r_array[i],16));
            let cP = public_keys[i].point.mul(web3.utils.toBN(c_array[i],16));
            ll_array.push(rG.add(cP)); //L' = rG + cP
        }
        return ll_array;
    }
    
    generate_rr(public_keys,c_array,r_array,hasher,key_image){
        let rr_array = [];
        for(let i=0;i<public_keys.length;i++){
            let cI = key_image.mul(web3.utils.toBN(c_array[i],16));
            let HpP = hasher.hash_point(public_keys[i].point);
            let rHp = HpP.mul(web3.utils.toBN(r_array[i],16));
            rr_array.push(cI.add(rHp));
        }
        return rr_array;
    }

    c_summation(c_array){
        let summation = web3.utils.toBN(0,16);
        for(let i=0;i<c_array.length;i++){
            summation = summation.add(c_array[i]);
        }
        return summation;
    }  
}
module.exports = Signature;