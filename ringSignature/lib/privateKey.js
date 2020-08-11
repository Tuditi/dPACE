const ecies = require('eth-ecies');
const Web3 = require('web3');
const web3 = new Web3();
const PublicKey = require('./publicKey.js');
const shuffle = require('shuffle-array');
const Signature = require('./signature.js');


//This is the random one-time secret key, which is used to calculate the key image.
//As a private key, we propose the private key concatenated with the randomly generated accessToken
class PrivateKey{
    constructor(identity, hasher){
        // identity is ethCrypto object: const identity = ethCrypto.createIdentity();
        this.counter = 0;
        this.value = web3.utils.toBN(identity);    
        this.hasher = hasher;
        this.public_keys = this.generateOTPK();
        this.key_image = this.hasher.hash_point(this.public_key.point).mul(this.value); //I = x*Hp(P), this needs to be changed in something specific for the transaction
    }

    get point(){
        return this.public_key.point;
    }

    generateOTPK(){
      console.log("Counter before:", this.counter)
      this.counter++;
      var OTPK_array = new Array();
      for (let i = this.counter; i <= 10+this.counter; i++) {
        const preimage = web3.utils.toBN(i).mul(this.value);
        const hash = this.hasher.hash_string(web3.utils.toHex(preimage));
        OTPK_array.push(new PublicKey(this.hasher.G.mul(hash)));
      };
      this.counter = i;
      return OTPK_array;
    }

    sign(message, foreign_keys){
        //The seed will provide randomness together with the keys.
        const message_digest = this.hasher.hash_string(message);
        const seed = this.hasher.hash_array([this.value,message_digest]);

        let all_keys = foreign_keys.slice();
        all_keys.push(this);
        shuffle(all_keys);

        const q_array = this.generate_q(all_keys,seed); // hex numbers
        const w_array = this.generate_w(all_keys,seed); // hex number + 1 BN


        const ll_array = this.generate_ll(all_keys,q_array,w_array);
        const rr_array = this.generate_rr(all_keys,q_array,w_array,this.key_image);
    
        //c = H_s(m, L_1, .., L_n, R_1, .., R_n) -> non-interactive challenge
        let challenge_arr = [message_digest];
        challenge_arr = challenge_arr.concat(ll_array);
        challenge_arr = challenge_arr.concat(rr_array);
        const challenge = this.hasher.hash_array(challenge_arr);

        const c_array = this.generate_c(all_keys,w_array,challenge);
        const r_array = this.generate_r(all_keys,q_array,c_array,challenge);
    
        let public_keys = [];
        for(let i=0;i<all_keys.length;i++){
          if(all_keys[i] instanceof PrivateKey){
            public_keys.push(all_keys[i].public_key);
          }else{
            public_keys.push(all_keys[i]);
          }
        }
    
        return new Signature(this.key_image,c_array,r_array,public_keys);
    }

    generate_q(all_keys,seed){
        let q_array = [];
        for(let i=0;i<all_keys.length;i++){
          let qi = this.hasher.hash_array(['q',seed,i]);
          q_array.push(qi);
        }
        return q_array;
      }
    
    generate_w(all_keys, seed) {
      let w_array = [];
      for (let i=0; i<all_keys.length; i++){
        if(all_keys[i] instanceof PublicKey) {
          w_array.push(this.hasher.hash_array(['w',seed,i]));
        } else {
          w_array.push(web3.utils.toBN(0,16));
        }
      }
      return w_array;
    }

    generate_ll(all_keys,q_array,w_array){
      let ll_array = [];
      for(let i=0;i<all_keys.length;i++){
        let lli = this.hasher.G.mul(web3.utils.toBN(q_array[i],16));
        ll_array.push(lli);
        if(all_keys[i] instanceof PublicKey){
          ll_array[i] = ll_array[i].add(all_keys[i].point.mul(web3.utils.toBN(w_array[i],16)));
        }
      }
      return ll_array;
    }

    generate_rr(all_keys,q_array,w_array,key_image){
      let rr_array = [];
  
      for(let i=0;i<all_keys.length;i++){
        let rri =all_keys[i].point;
        rri = this.hasher.hash_point(rri);
        rri = rri.mul(web3.utils.toBN(q_array[i],16));
        if(all_keys[i] instanceof PublicKey){
          rri = rri.add(key_image.mul(web3.utils.toBN(w_array[i],16)));
        }
        rr_array.push(rri);
      }
      return rr_array;
    }

    generate_c(all_keys,w_array,challenge){
      let c_array = [];
      for(let i=0;i<all_keys.length;i++){
        if(all_keys[i] instanceof PublicKey){
          c_array.push(web3.utils.toBN(w_array[i],16));
        }else{
          let chNum = web3.utils.toBN(challenge);
          let wSum = w_array.reduce((acc,val) => {return acc = acc.add(web3.utils.toBN(val,16));},web3.utils.toBN(0,16));
          let ci = chNum.sub(wSum).umod(this.hasher.l);
          c_array.push(ci);
        }
      }
      return c_array;
    }

    generate_r(all_keys,q_array,c_array){
      let r_array = [];
      for(let i=0;i<all_keys.length;i++){
        if(all_keys[i] instanceof PublicKey){
          r_array.push(web3.utils.toBN(q_array[i],16));
        }else{
          let ri = web3.utils.toBN(q_array[i],16).sub(all_keys[i].value.mul(c_array[i]));
          ri = ri.umod(this.hasher.l);
          r_array.push(ri);
        }
      }
      return r_array;
    }
}

module.exports = PrivateKey;

