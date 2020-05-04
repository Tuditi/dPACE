const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require ('web3');
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const EthCrypto = require('eth-crypto');
const ecies = require('eth-ecies');
require('events').EventEmitter.defaultMaxListeners = 100;

const web3 = new Web3(ganache.provider());
const {abi, evm} = require('../compile');
const MAX_GAS = '6721975'

let contract;     //Holds instance of our contract
let accounts;     //Holds instance of accounts
//Different users & their keys that are generated:

const user0 = EthCrypto.createIdentity();
const user1 = EthCrypto.createIdentity();
const user2 = EthCrypto.createIdentity();

//Info concerning RSP:
const RSPAddress = 0x1900A200412d6608BaD736db62Ba3352b1a661F2;
const publicKeyRSP = '86b41d0c97dd302e7df473f243766ef803afabd2c93ddc9f670e059494eb66587bf3759c938d2c73f132697fd824496be4001849c3dff06f569de3b7bd63d491';
const privateKeyRSP = 'ff6415f9fd0b8d9b3712843c53048b27a51171ce713517f42f4820e74310f614';

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
            },
            {
                secretKey: '0x6bc48fee787b0809c3e8fe3fe854e9319ff2d50fbbe5f6d5f1dc3c2602d56ac4',
                balance: web3.utils.toWei('100', 'ether')
            }
        ]
        
    })
    web3.setProvider(ganacheProvider);
    
    accounts = await new web3.eth.getAccounts();
    contract = await new web3.eth.Contract(abi)
        .deploy({data: evm.bytecode['object']})
        .send({ from: user0.address, gas: MAX_GAS});

    await contract.methods.deployCar(BMW_address,BMW_accessToken,BMW_location,BMW_details, web3.utils.toWei('0.000011574','ether'),'Rita').send({
        from: user0.address,
        value: web3.utils.toWei('5','ether'),
        gas: MAX_GAS
    });

    await contract.methods.deployCar(Audi_address,Audi_accessToken,Audi_location,Audi_details, web3.utils.toWei('2','ether'),'Bernard').send({
        from: user1.address,
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

    //Enter 3 Renters (David, Kristof, Rebecca)
    const signature_0 = EthCrypto.sign(privateKeyRSP,proofHash);
    const vrs0 = EthCrypto.vrs.fromString(signature_0);
    
    await contract.methods.enterRenter('David', proofHash, vrs0.v, vrs0.r, vrs0.s).send({
        from: user0.address,
        value: web3.utils.toWei('5','ether'),
        gas: MAX_GAS
    });
    
    const signature_1 = EthCrypto.sign(privateKeyRSP,proofHash);
    const vrs1 = EthCrypto.vrs.fromString(signature_1);

    await contract.methods.enterRenter('Kristof',proofHash, vrs1.v, vrs1.r, vrs1.s).send({
        from: user1.address,
        value: web3.utils.toWei('5','ether'),
        gas: MAX_GAS
    });

    const signature_2 = EthCrypto.sign(privateKeyRSP,proofHash);
    const vrs2 = EthCrypto.vrs.fromString(signature_2);

    await contract.methods.enterRenter('Rebecca',proofHash, vrs2.v, vrs2.r, vrs2.s).send({
        from: user2.address,
        value: web3.utils.toWei('50','ether'),
        gas: MAX_GAS
    });
});

describe('Car Deployment', async() => {
    it('Deploys a contract', async() => {
        assert.ok(contract.options.address);
    });

    describe('initialization', () => {
        it('Checks if cars properly initialized:', async() => {
            const BMW = await contract.methods.getCar(BMW_address).call();
            const Audi = await contract.methods.getCar(Audi_address).call();
 
            assert.equal(BMW.owner, user0.address);
            assert.equal(Audi.owner, user1.address);
        });

        it('Renters properly initialized', async() => {
            const renter0 = await contract.methods.getRenter(user0.address).call();
            const renter1 = await contract.methods.getRenter(user1.address).call();
            const renter2 = await contract.methods.getRenter(user2.address).call();

            assert.equal(renter0.addr,user0.address);
            assert.equal(renter1.addr,user1.address);
            assert.equal(renter2.addr,user2.address);
        });
    });
    
    it('Valid booking BMW', async() => {
        const car = await contract.methods.getCar(BMW_address).call();
        //signs and encrypts the valid accessToken
        const hashToken = EthCrypto.hash.keccak256(car.accessToken);
        const signature = EthCrypto.sign(user2.privateKey, hashToken);
       
        const encryptedAT = encrypt(BMW_publicKey,signature);
        
        await contract.methods.bookCar(BMW_address, '0x'+encryptedAT).send({
            from: user2.address,
            gas: MAX_GAS
        });

        const renter = await contract.methods.getRenter(user2.address).call();
        const timestamp = Math.floor(Date.now()/1000);
    
        assert(timestamp - renter.startTime<10);
        assert.equal(renter.car, BMW_address);
        assert.equal(renter.occupied,true);
        assert.equal(renter.accessToken.slice(2),encryptedAT);

        const decryptedSig = decrypt(BMW_privateKey.slice(2), renter.accessToken.slice(2));
        //Check signature
        
        const senderAddr = EthCrypto.recover(
            decryptedSig,
            EthCrypto.hash.keccak256(car.accessToken)
        );
        assert.equal(senderAddr,user2.address)
    });
   
    it('Already borrowed a car', async() => {
        var car = await contract.methods.getCar(BMW_address).call();
        //signs and encrypts the valid accessToken
        var hashToken = EthCrypto.hash.keccak256(car.accessToken);
        var signature = EthCrypto.sign(user2.privateKey, hashToken);
        
        var encryptedAT = encrypt(BMW_publicKey,signature);
        
        await contract.methods.bookCar(BMW_address, '0x' + encryptedAT).send({
            from:user2.address,
            gas: MAX_GAS
        });
        try {
            car = await contract.methods.getCar(Audi_address).call();
            //signs and encrypts the valid accessToken
            hashToken = EthCrypto.hash.keccak256(car.accessToken);
            signature = EthCrypto.sign(user2.privateKey, hashToken);
            encryptedAT = encrypt(Audi_publicKey,signature);
            
            await contract.methods.bookCar(Audi_address, '0x'+encryptedAT).send({
                from: user2.address,
                gas: MAX_GAS
            });
        } catch(err) {
            console.log(err);
            assert(err); 
            return;   
        };
        assert(false);
    });

     it('Valid booking Audi', async() => {
        const car = await contract.methods.getCar(Audi_address).call();
        //signs and encrypts the valid accessToken
        const hashToken = EthCrypto.hash.keccak256(car.accessToken);
        const signature = EthCrypto.sign(user2.privateKey, hashToken);
        const encryptedAT = encrypt(Audi_publicKey,signature);
        
        await contract.methods.bookCar(Audi_address, '0x'+encryptedAT).send({
            from: user1.address,
            gas: MAX_GAS
        });
        const updatedRenter = await contract.methods.getRenter(user1.address).call();
        
        assert.equal(updatedRenter.car, car.carHW);
        assert.equal(updatedRenter.accessToken, '0x'+encryptedAT);
    });

    it('Insufficient funds', async() => {
        //Deplete balance renter
        await contract.methods.withdrawBalanceRenter().send({
            from: user0.address,
            gas: MAX_GAS
        })

        const car = await contract.methods.getCar(Audi_address).call();
        //signs and encrypts the valid accessToken
        const hashToken = EthCrypto.hash.keccak256(car.accessToken);
        const signature = EthCrypto.sign(user2.privateKey, hashToken);
        const encryptedAT = encrypt(Audi_publicKey,signature);

        try{
            await contract.methods.bookCar(Audi_address,encryptedAT).send({
            from: user0.address,
            gas: MAX_GAS
            });
        } catch(err) {
            console.log('Caught error in insufficient funds:', err.name);
            assert(err);
            return;
        }
        assert(false);
    });
    


});

// Functions for advancing time
advanceTime = (time) => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [time],
        id: new Date().getTime()
      }, (err, result) => {
        if (err) { return reject(err) }
        return resolve(result)
      })
    })
  }
  
  advanceBlock = () => {
    return new Promise((resolve, reject) => {
      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: new Date().getTime()
      }, (err, result) => {
        if (err) { return reject(err) }
        const newBlockHash = web3.eth.getBlock('latest').hash
  
        return resolve(newBlockHash)
      })
    })
  }
  advanceTimeAndBlock = async (time) => {
    await advanceTime(time)
    await advanceBlock()
    return Promise.resolve(web3.eth.getBlock('latest'))
  }
