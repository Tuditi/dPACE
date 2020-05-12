const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require ('web3');
require('events').EventEmitter.defaultMaxListeners = 100;
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const web3 = new Web3();

//Need for validating signature
const EthCrypto = require('eth-crypto');
const ecies = require("eth-ecies");

//Different users & their keys that are generated:

const user0 = EthCrypto.createIdentity();
const user1 = EthCrypto.createIdentity();
const user2 = EthCrypto.createIdentity();

//Addresses cars:

//Variables to initiate BMW
const BMW_address = '0x5ba7c96BB7707A83AFC2150BfFC81715c3090F04';
const BMW_privateKey = '0x6bc48fee787b0809c3e8fe3fe854e9319ff2d50fbbe5f6d5f1dc3c2602d56ac4';
const BMW_publicKey =   '1fa124c4281fab15064cd5072f60bb6bd925aaa097b22d6fc6c61e019434349802f7898e3849f4ef6aaf8ce052cf6df8ca6ea6ff4072392f6726ae0e8db4760d'

//Variables to initiate Audi
const Audi_address = '0xD21CC33d0CF03675BE89aF7197338a4165751a2E';
const Audi_privateKey = '0x974cc12dfb97b945f97a826ef944abe01303bf3e662f2374bddc17aabf83a708';
const Audi_publicKey = '5a263ed4bc58fa902a71813e851ab2425b8ec696862c16fb3132ba3a5e8e4085abcfcb8ad6c9958d6439812ee2ade7a67eddd76c9829a4eea1f2a5acea996c88';

//Variables to initiate Tesla
const Tesla_address = '0xc18EdD64D4Dc43C4e1AC22A670eF1F482287C39b';
const Tesla_privateKey = '0x8860107c55e633f580c5c20eda7757bcc02c1fa2543a6d619700b492d7b2483c';
const Tesla_publicKey =   '8bb42e5b70bfd1c38b2dfdc5da499fd7b169a1907789383b6ec99c7d8c7ab90802b2109f6c984e009f2863579a4d6a5428d21fa3f881fc952d05be3582e74552';

//Variables to initiate Mercedes

const Merc_address = '0x2a63100f352FC1005Ccd80aFe8eB5F3E5BDFbf3d';
const Merc_privateKey = '0xe8c4ee72dec852d020f3f04a593b12c6f2dd2421bfde6e025956c59840c79650';
const Merc_publicKey = 'b325d889d122fb4a3ed05d217df5d44444ad699226df7e46b317c65bfeaf346b4d2ae9da143ea1e880080e247e563a8969c8e0f111b655d5ede50b74060749da';

//Variables for the alt_bn128 curve
const G1 = [1,2];

//functions to perform cryptographic operations
function hashPoint(point){
    assert.equal(point.length,2);
    var onCurve  = false;
    var hash = [web3.utils.soliditySha3(point[0], point[1]), 0]
    while( !onCurve ) {
        hash[1], onCurve = EvaluateCurve(hash[0]);
        hash[0]++;
    }
    return hash
}

function encrypt(publicKey, data) {
    let userPublicKey = new Buffer.from(publicKey, 'hex');
    let bufferData = new Buffer.from(data);
    let encryptedData = ecies.encrypt(userPublicKey, bufferData);
    return encryptedData.toString('hex');
}

function decrypt(privateKey, encryptedData) {
    let userPrivateKey = new Buffer.from(privateKey, 'hex');
    let bufferEncryptedData = new Buffer.from(encryptedData, 'hex');
    let decryptedData = ecies.decrypt(userPrivateKey, bufferEncryptedData);
    return decryptedData.toString('utf8');
}

function ringSign(ringMessage, data) {

}

const {abi, evm} = require('../compile');
const MAX_GAS = '6721975';

let contract;     //Holds instance of our contract
let accounts;

var proofOfRegistration = "Valid driver's license";
