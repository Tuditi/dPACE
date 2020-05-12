const Web3 = require('web3');
const web3 = new Web3();
const EcDSA = require('elliptic');
const PublicKey = require('./publicKey.js');


class Hasher{
    constructor(){
        this.ec = new EcDSA.ec("bn256");
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
    ///Function doesn't work, because the has needs to be the x coordinate and then we need to find the corresponding y-coordinate.
    hash_point(point){
        let pointArr = [point.x,point.y];
        let moduloHash = web3.utils.toBN(this.hash_array(pointArr)); //Check whether this modulo has to be here?
        return this.G.mul(moduloHash);
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
