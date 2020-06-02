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

const user0Address = user0.address;
const user1Address = user1.address;
const user2Address = user2.address;

const user0sK = user0.privateKey.slice(2);
const user1sK = user1.privateKey.slice(2);
const user2sK = user2.privateKey.slice(2);

/* createRSP.js used to generate RSP identity {
  address: '0x1900A200412d6608BaD736db62Ba3352b1a661F2',
  privateKey: '0xff6415f9fd0b8d9b3712843c53048b27a51171ce713517f42f4820e74310f614',
  publicKey: '86b41d0c97dd302e7df473f243766ef803afabd2c93ddc9f670e059494eb66587bf3759c938d2c73f132697fd824496be4001849c3dff06f569de3b7bd63d491'
} */
;
const RSPAddress = 0x1900A200412d6608BaD736db62Ba3352b1a661F2;
const publicKeyRSP = '86b41d0c97dd302e7df473f243766ef803afabd2c93ddc9f670e059494eb66587bf3759c938d2c73f132697fd824496be4001849c3dff06f569de3b7bd63d491';
const privateKeyRSP = 'ff6415f9fd0b8d9b3712843c53048b27a51171ce713517f42f4820e74310f614';

const {abi, evm} = require('../compile');
const MAX_GAS = '6721975';

let contract;     //Holds instance of our contract

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
        
    })
    web3.setProvider(ganacheProvider);

    contract = await new web3.eth.Contract(abi)
        .deploy({data: evm.bytecode['object']})
        .send({ from: user0.address, gas: MAX_GAS});

});

describe('Enter Renter', () => {
    it('deploys a contract', () => {
        assert.ok(contract.options.address);
    });

    it('Valid signature0', async() => {

        const proofHash = EthCrypto.hash.keccak256([
            {// prefix
                type: 'string',
                value: 'Registration Proof:'
            }, { // contractAddress
                type: 'address',
                value: user0Address
            }, { // proof of registration is contained here
                type: 'string',
                value: proofOfRegistration
            }]);
            
        const signature_0 = EthCrypto.sign(privateKeyRSP,proofHash);
        const vrs0 = EthCrypto.vrs.fromString(signature_0);

        await contract.methods.enterRenter('David',proofHash, vrs0.v, vrs0.r, vrs0.s).send({
            from: user0.address,
            value: web3.utils.toWei('5','ether'),
            gas: MAX_GAS
        });

        const renter = await contract.methods.getRenter(user0.address).call();
        
        assert.equal(renter.addr, user0Address);
        assert.equal(renter.balance, web3.utils.toWei('5','ether'));
        assert.equal(renter.proof, proofHash);
        assert.equal(renter.occupied, false);
        assert.equal(renter.car,'0x0000000000000000000000000000000000000000');
        assert.equal(renter.name,'David');   
    });
    
    it('Valid signature1, not enough ether', async() => {
        const proofHash = EthCrypto.hash.keccak256([
            {// prefix
        type: 'string',
        value: 'Registration Proof:'
    }, { // contractAddress
        type: 'address',
        value: user1Address
    }, { // proof of registration is contained here
        type: 'string',
        value: proofOfRegistration
    }]);
        const signature_1 = EthCrypto.sign(privateKeyRSP,proofHash);
        const vrs1 = EthCrypto.vrs.fromString(signature_1);

        try {await contract.methods.enterRenter('Kristof',proofHash, vrs1.v, vrs1.r, vrs1.s).send({
            from: user1.address,
            value: web3.utils.toWei('4','ether'),
            gas: MAX_GAS
        });
        } catch(err) {
            assert(err);
        }
      
    });
    
    it('Valid signature2', async() => {
        const proofHash = EthCrypto.hash.keccak256([
            {// prefix
        type: 'string',
        value: 'Registration Proof:'
    }, { // contractAddress
        type: 'address',
        value: user2Address
    }, { // proof of registration is contained here
        type: 'string',
        value: proofOfRegistration
    }]);
        const signature_2 = EthCrypto.sign(privateKeyRSP,proofHash);
        const vrs2 = EthCrypto.vrs.fromString(signature_2);

        await contract.methods.enterRenter('Kristof',proofHash, vrs2.v, vrs2.r, vrs2.s).send({
            from: user2.address,
            value: web3.utils.toWei('5','ether'),
            gas: MAX_GAS
        });

        const renter = await contract.methods.getRenter(user2.address).call();

        assert.equal(renter.addr, user2.address);
        assert.equal(renter.balance, web3.utils.toWei('5','ether'));
        assert.equal(renter.proof, proofHash);
        assert.equal(renter.occupied, false);
        assert.equal(renter.car,'0x0000000000000000000000000000000000000000');
        assert.equal(renter.name,'Kristof');
    });

    it('Valid signature2, but already inside list of renters', async() => {
        const proofHash = EthCrypto.hash.keccak256([
            {// prefix
                type: 'string',
                value: 'Registration Proof:'
            }, { // contractAddress
                type: 'address',
                value: user0Address
            }, { // proof of registration is contained here
                type: 'string',
                value: proofOfRegistration
            }]);
            
        const signature_2 = EthCrypto.sign(privateKeyRSP,proofHash);
        const vrs2 = EthCrypto.vrs.fromString(signature_2);

        await contract.methods.enterRenter('David',proofHash, vrs2.v, vrs2.r, vrs2.s).send({
            from: user2.address,
            value: web3.utils.toWei('5','ether'),
            gas: MAX_GAS
        });

        try{ 
            await contract.methods.enterRenter('David', proofHash, vrs2.v, vrs2.r, vrs2.s).send({
                from: user2.address,
                value: web3.utils.toWei('5','ether'),
                gas: MAX_GAS
            });
        } catch(err) {
            assert(err);
            return;
        };
        assert(false);
       
    })
})