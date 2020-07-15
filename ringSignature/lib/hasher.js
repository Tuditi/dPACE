const Web3 = require('web3');
const web3 = new Web3();
const EcDSA = require('elliptic');
const PublicKey = require('./publicKey.js');


class Hasher{
    constructor(){
        this.ec = new EcDSA.ec("bn256");
    }

    get curve(){
        return this.ec.curve;
    }
    //correct values
    get G(){
        return this.ec.g;
    }

    get l(){
        return this.ec.curve.n;
    }

    // A cryptographic Hash function H_s
    hash_string(message){
        let msgHash = web3.utils.soliditySha3(message)
        msgHash = web3.utils.toBN(msgHash);
        msgHash = msgHash.mod(this.l);
        msgHash = msgHash.toString(16);

        return msgHash;
    }
    //Function that hashes the x-coodinate and calculates the corresponding y-coordinate
    hash_point(point){
        console.log("Y-value of point(JS):")
        let hash = web3.utils.toBN(web3.utils.soliditySha3(point.x));
        let mod_hash = hash.mod(this.l);
        let on_curve = false;
        while(!on_curve){
            try{
                point = this.ec.curve.pointFromX(mod_hash,true);
                on_curve = true;
            } catch(err) {
                mod_hash = mod_hash.add(web3.utils.toBN(1,16));
            }
        }
        return point;
    }

    evaluate_curve(x){
        let point;
        let on_curve;
        try{
            point = this.ec.curve.pointFromX(x,false);
            on_curve = true;
        } catch(err) {
            point = 0;
            on_curve = false;
        }
        
        return point;

    }

    hash_array(array){
        let hash_array = [];
        let string_array = [];

        for(let i=0;i<array.length;i++){
        if(array[i] != undefined && Array.isArray(array[i])){
            hash_array.push(this.hash_array(array[i]));
        }else if(array[i] instanceof PublicKey){
            hash_array.push(this.hash_point(array[i].point))
        }else if(web3.utils.isBN(array[i])){
            let hash_i = array[i].toString(16);
            hash_i = this.hash_string(hash_i);
            hash_array.push(hash_i);
        }else if(typeof array[i] === 'string'){
            hash_array.push(this.hash_string(array[i]));
        }else if(typeof array[i] === 'number'){
            string_array.push(this.hash_string(array[i]));
            hash_array.push(this.hash_string(array[i].toString()));
        }else if(array[i].x !== undefined && array[i].y !== undefined){
            hash_array.push(this.hash_string(array[i].encode('hex').toString()));
        }else{
            console.log(array[i]);
            throw 'hash_array() case not implemented';
        }
        }
        let concat = hash_array.reduce((acc,val) => {return acc += val.toString();});

        return this.hash_string(concat);
    }

}

module.exports = Hasher;
