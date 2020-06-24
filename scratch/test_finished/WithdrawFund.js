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

    await contract.methods.deployCar(BMW_address,BMW_accessToken,BMW_location,BMW_details, web3.utils.toWei('0.000011574','ether'),'Rita').send({
        from: user0.address,
        value: web3.utils.toWei('10','ether'),
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

    const signature_2 = EthCrypto.sign(privateKeyRSP,proofHash);
    const vrs2 = EthCrypto.vrs.fromString(signature_2);

    await contract.methods.enterRenter('Rebecca',proofHash, vrs2.v, vrs2.r, vrs2.s).send({
        from: user2.address,
        value: web3.utils.toWei('50','ether'),
        gas: MAX_GAS
    })
});

describe('Check Withdrawal and Funding', async() => {
    it('withdraw balance owner that has 10 ether', async() =>{
        const balanceBefore = await web3.eth.getBalance(accounts[0]);
        console.log('Amount of Ether inside account0 after deploying car:', balanceBefore);
        await contract.methods.withdrawBalanceOwner().send({
            from:accounts[0],
            gas: MAX_GAS
        });
        const balanceAfter = await web3.eth.getBalance(accounts[0]);
        const balanceContract = await contract.methods.getBalanceOwner().call({
            from: user0.address,
            gas: MAX_GAS
        })
        assert.equal(balanceContract,web3.utils.toWei('5','ether'));
        assert(balanceAfter-balanceBefore > web3.utils.toWei('4.9','ether'));
    });
    
    it('withdraw balance owner that has 5 ether', async() =>{
        try{
            await contract.methods.withdrawBalanceOwner().send({
                from:accounts[1],
                gas: MAX_GAS
            });
        } catch(err) {
            assert(err);
            return;
        }
        assert(false);
    });
    
    it('withdraw balance renter', async() =>{
        const balanceBefore = await web3.eth.getBalance(accounts[0]);
        await contract.methods.withdrawBalanceRenter().send({
            from:accounts[0],
            gas: MAX_GAS
        });
        const balanceAfter = await web3.eth.getBalance(accounts[0]);
        assert(balanceAfter-balanceBefore > web3.utils.toWei('9.9','ether'));
        assert(balanceAfter-balanceBefore < web3.utils.toWei('10.1','ether'));
    });

      
    it('withdraw balance renter while driving', async() =>{
        const car = await contract.methods.getCar(BMW_address).call();
        //signs and encrypts the valid accessToken
        const hashToken = EthCrypto.hash.keccak256(car.accessToken);
        const signature = EthCrypto.sign(user1.privateKey, hashToken);
       
        const encryptedAT = encrypt(BMW_publicKey,signature);
        
        await contract.methods.bookCar(BMW_address, '0x'+encryptedAT).send({
            from: user1.address,
            gas: MAX_GAS
        });
        
        try{
            await contract.methods.withdrawBalanceRenter().send({
                from:accounts[1],
                gas: MAX_GAS
            });
        } catch (err) {
            assert(err);
            return;
        }
        assert(false);
    });

    it('fund balance owner', async() =>{
        const balanceBefore = await contract.methods.getBalanceOwner().call({from:accounts[0]});
        await contract.methods.fundBalanceOwner().send({
            from: accounts[0],
            value: web3.utils.toWei('20','ether'),
            gas: MAX_GAS
        });
        const balanceAfter = await contract.methods.getBalanceOwner().call({from:accounts[0]});
        assert(balanceAfter-balanceBefore == web3.utils.toWei('20', 'ether'));
    });   
    
    it('fund balance renter', async() =>{
        const balanceBefore = await contract.methods.getBalanceRenter().call({from:accounts[1]});
        await contract.methods.fundBalanceRenter().send({
            from: accounts[1],
            value: web3.utils.toWei('20','ether'),
            gas: MAX_GAS
        });
        const balanceAfter = await contract.methods.getBalanceRenter().call({from:accounts[1]});
        assert(balanceAfter-balanceBefore == web3.utils.toWei('20', 'ether'));
    });
    
    /*it('underflow', async() =>{
        const balanceBefore = await contract.methods.getBalanceOwner().call({from:accounts[1]});
        console.log('UNDERFLOW!');
        console.log('Balance Before:', balanceBefore);
        const car = await contract.methods.getCar(BMW_address).call();
        //signs and encrypts the valid accessToken
        const hashToken = EthCrypto.hash.keccak256(car.accessToken);
        const signature = EthCrypto.sign(user1.privateKey, hashToken);
       
        const encryptedAT = encrypt(BMW_publicKey,signature);
        
        await contract.methods.bookCar(BMW_address, '0x'+encryptedAT).send({
            from: user1.address,
            gas: MAX_GAS
        });
        

        await advanceTimeAndBlock(86400);

        await contract.methods.endRentCar(Audi_address).send({
            from:accounts[1],
            gas: MAX_GAS
        });
                
        const balanceAfter = await contract.methods.getBalanceOwner().call({from:accounts[1]});
        console.log('Balance After:', balanceAfter);
    });*/

});
