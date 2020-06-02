const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require ('web3');
require('events').EventEmitter.defaultMaxListeners = 100;
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const web3 = new Web3();
const Prng = require('../ownSignature/lib/prng');

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
const BMW_accessToken = '0x2254686973206973207468652061636365737320636f64652031323334353622'; //'This is the access code 12';
const BMW_location = '0x225363686f75777665676572737472616174323a32303430426572656e647222'; //'Schouwvegerstraat2:2040Berendr';
const BMW_details = '0x225363686f75777665676572737472616174323a32303430426572656e647222'; //'BMW A5-klasse, gekke waggie123'
const BMW_privateKey = '0x6bc48fee787b0809c3e8fe3fe854e9319ff2d50fbbe5f6d5f1dc3c2602d56ac4';
const BMW_publicKey =   '1fa124c4281fab15064cd5072f60bb6bd925aaa097b22d6fc6c61e019434349802f7898e3849f4ef6aaf8ce052cf6df8ca6ea6ff4072392f6726ae0e8db4760d'

//Variables to initiate Audi
const Audi_address = '0xD21CC33d0CF03675BE89aF7197338a4165751a2E';
const Audi_accessToken = '0x27417564694135416363657373546f6b656e49734c69742c766965736c697427'; //'AudiA5AccessTokenIsLit,vieslit';
const Audi_location = '0x225363686f75777665676572737472616174323a32303430426572656e647222'; //'Schouwvegerstraat2:2040Berendr';
const Audi_details = '0x274175646941352d6b6c617373652c2067656b6b652077616767696531323327'; //'AudiA5-klasse, gekke waggie123'
const Audi_publicKey = '5a263ed4bc58fa902a71813e851ab2425b8ec696862c16fb3132ba3a5e8e4085abcfcb8ad6c9958d6439812ee2ade7a67eddd76c9829a4eea1f2a5acea996c88';
var proofOfRegistration = "Valid driver's license";

//functions to encrypt and decrypt accessTokens
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

const RSPAddress = 0x1900A200412d6608BaD736db62Ba3352b1a661F2;
const publicKeyRSP = '86b41d0c97dd302e7df473f243766ef803afabd2c93ddc9f670e059494eb66587bf3759c938d2c73f132697fd824496be4001849c3dff06f569de3b7bd63d491';
const privateKeyRSP = 'ff6415f9fd0b8d9b3712843c53048b27a51171ce713517f42f4820e74310f614';

const {abi, evm} = require('../compile');
const MAX_GAS = '6721975';

let contract;     //Holds instance of our contract
let accounts;

var proofOfRegistration = "Valid driver's license";

beforeEach(async() => {
    const ganacheProvider = ganache.provider({
        accounts: [
            {
                secretKey: user0.privateKey,
                balance: web3.utils.toWei('100', 'ether')
            },
            {
                secretKey: user1.privateKey,
                balance: web3.utils.toWei('100', 'ether')
            },
            {
                secretKey: user2.privateKey,
                balance: web3.utils.toWei('100', 'ether')
            }
        ]
        
    });
    web3.setProvider(ganacheProvider);

    accounts = await new web3.eth.getAccounts();
    contract = await new web3.eth.Contract(abi)
        .deploy({data: evm.bytecode['object']})
        .send({ from: user0.address, gas: MAX_GAS});

    //Deploy the BMW & the Audi inside the smart contract
    await contract.methods.deployCar(BMW_address,BMW_accessToken,BMW_location,BMW_details, web3.utils.toWei('0.000011574','ether'),'Rita').send({
        from: user0.address,
        value: web3.utils.toWei('10','ether'),
        gas: MAX_GAS
    });

    await contract.methods.deployCar(Audi_address,Audi_accessToken,Audi_location,Audi_details, web3.utils.toWei('2','ether'),'Bernard').send({
        from: user2.address,
        value: web3.utils.toWei('5','ether'),
        gas: MAX_GAS
    });

    // This is the same proof for everyone atm!!
    const proofHash = EthCrypto.hash.keccak256([
        {// prefix
            type: 'string',
            value: 'Registration Proof:'
        }, { // contractAddress
            type: 'address',
            value: user0.address
        }, { // proof of registration is contained here
            type: 'string',
            value: proofOfRegistration
        }
    ]);

    //Enter 2 Renters (David, Kristof)
    const signature_0 = EthCrypto.sign(privateKeyRSP,proofHash);
    const vrs0 = EthCrypto.vrs.fromString(signature_0);
    
    await contract.methods.enterRenter('David', proofHash, vrs0.v, vrs0.r, vrs0.s).send({
        from: user0.address,
        value: web3.utils.toWei('10','ether'),
        gas: MAX_GAS
    });
    
    const signature_1 = EthCrypto.sign(privateKeyRSP,proofHash);
    const vrs1 = EthCrypto.vrs.fromString(signature_1);

    await contract.methods.enterRenter('Kristof',proofHash, vrs1.v, vrs1.r, vrs1.s).send({
        from: user1.address,
        value: web3.utils.toWei('5','ether'),
        gas: MAX_GAS
    });

    //David books BMW
    //signs and encrypts the valid accessToken
    var hashToken = EthCrypto.hash.keccak256(BMW_accessToken);
    var signature = EthCrypto.sign(user0.privateKey, hashToken);
    var encryptedAT = encrypt(BMW_publicKey,signature);
    
    await contract.methods.bookCar(BMW_address, '0x'+encryptedAT).send({
        from: user0.address,
        gas: MAX_GAS
    });

    //Kristof books Audi
    //signs and encrypts the valid accessToken
    hashToken = EthCrypto.hash.keccak256(Audi_accessToken);
    signature = EthCrypto.sign(user1.privateKey, hashToken);
    encryptedAT = encrypt(BMW_publicKey,signature);
    
    await contract.methods.bookCar(BMW_address, '0x'+encryptedAT).send({
        from: user1.address,
        gas: MAX_GAS
    });
});

describe("End driving by the car:", () =>{
    it('deploys a contract', () => {
        assert.ok(contract.options.address);
    });

    it('initialization happened correctly', async() =>{
        const bmw = await contract.methods.getCar(BMW_address);
        const audi = await contract.methods.getCar(Audi_address);
        const david = await contract.methods.getRenter(user0.address);
        const kristof = await contract.methods.getRenter(user1.address);

        assert.equal(david.car,bmw.carHW);
        assert.equal(kristof.car,audi.carHW);
    });

    it('BMW ends driving upon receiving valid token', async() =>{
        const renter = await contract.methods.getRenter(user0.address);
        const decryptedSig = decrypt(BMW_privateKey.slice(2),renter.accessToken);

    })
})
//Untested functions needed for the thesis!
async function carFinish(car, renter, start, index, publicKeys) {
    //Fee calculation
    const timestamp = getTime();
    const fee = car.price * (timestamp - start);
    //Blind fee according in the same way as ZoKrates: HOW TO DO THIS???
    const r = new Prng().random;
    const blindedFee = await EthCrypto.encryptWithPublicKey(
        renter.publicKey,
        fee.concat(r)
    );
    //Generate signatures
    const rSignature = await ringSign(blindedFee, car, index, publicKeys);
    const signedTime = EthCrypto.sign(
        car.privateKey,
        EthCrypto.hash.keccak256(timestamp)
    );
    return {
        blindedFee: blindedFee,
        randomness: r,
        timestamp:  timestamp,
        signature:  signedTime,
        rSignature: rSignature
    };
}

async function renterFinish(message, renter, car, index, publicKeys){
    //Check correctness fee
    const decryptedPayload = await EthCrypto.decryptWithPrivateKey(
        renter.privateKey,
        message.blindedFee
    );
    const unblindedFee = decryptedPayload.slice(0,unblindedFee-message.r.length);
    if (unblindedFee != (message.timestamp-car.start)*car.price){
        throw "Incorrect fee";
    };
    //Check signatures
    if (car.address != EthCrypto.recover(
        message.signature,
        EthCrypto.hash.keccak256(message.timestamp)
    )){
        throw "Invalid Signature!";
    };
    const valid = await contract.methods.ringVerify(hashLock, ringSignature).call({
        from: renter.address,
        gas: MAX_GAS
    })
    if (!valid){
        throw "Invalid Ring Signature!";
    }
    //Generate ring signature
    const rSignature = await ringSign(message.signature, renter, index, publicKeys);
    return rSignature;
}

function generateHashLock(){
    const prn = new Prng().random;
    return {
        preimage: prn,
        hashLock: web3.utils.soliditySha3(prn)
    };    
}

async function ringSign(msg, user,  index, publicKeys){
    publicKeys.slice(index, user.publicKey);

    const randomNumbers = new Array();
    for (let i = 0; i < publicKeys.length; i++){
        randomNumbers.push(new Prng().random);
    };
    
    const data = [index, user.privateKey].concat(
        randomNumbers.concat(publicKeys));

    const signature = await contract.methods.RingSign(msg,data).call({
        from: user.address,
        gas: MAX_GAS
    });
    return signature;
};