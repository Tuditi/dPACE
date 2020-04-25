const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require ('web3');
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const EthCrypto = require('eth-crypto');
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

//Variables to initiate Audi
const Audi_address = '0xD21CC33d0CF03675BE89aF7197338a4165751a2E';
const Audi_accessToken = '0x27417564694135416363657373546f6b656e49734c69742c766965736c697427'; //'AudiA5AccessTokenIsLit,vieslit';
const Audi_location = '0x225363686f75777665676572737472616174323a32303430426572656e647222'; //'Schouwvegerstraat2:2040Berendr';
const Audi_details = '0x274175646941352d6b6c617373652c2067656b6b652077616767696531323327'; //'AudiA5-klasse, gekke waggie123'

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
    
    it('Valid car rental BMW', async() => {
        const checkRent = await contract.methods.rentCar(BMW_address).send({
            from: user2.address,
            gas: MAX_GAS
        });
        const updatedRenter = await contract.methods.getRenter(user2.address).call();
        const car = await contract.methods.getCar(BMW_address).call();
        const timestamp = Math.floor(Date.now()/1000);
    
        assert.equal(car.renter,user2.address);
        assert.equal(car.available, false);
        assert(timestamp - car.startTime<10);
        assert.equal(updatedRenter.car, BMW_address);
        assert.equal(updatedRenter.driving,true);
    });

    it('Already borrowed a car', async() => {
        await contract.methods.rentCar(BMW_address).send({
            from:user2.address,
            gas: MAX_GAS
        });
        try {
            await contract.methods.rentCar(Audi_address).send({
                from: user2.address,
            });
        } catch(err) {
            assert(err); 
            return;   
        };
        assert(false);
    });

    it('Car currently in use', async() => {
        await contract.methods.rentCar(BMW_address).send({
            from:user2.address,
            gas: MAX_GAS
        });
        try {
            await contract.methods.rentCar(BMW_address).send({
                from: user0.address,
            });
        } catch(err) {
            assert(err);
            return;
        };
        assert(false);
    });

    it('Try to end rental period of car that is not rented out', async() => {
        try {
           await contract.methods.endRentCar(Audi_address).send({from:user2.address});
        } catch(err) {
            assert(err);
            return;
        }
        assert(false); 
    });

    it('Try to end rental period of car that is rented out by someone else', async() => {
        await contract.methods.rentCar(BMW_address).send({
            from: user2.address,
            gas: MAX_GAS
        });

        try {
           await contract.methods.endRentCar(BMW_address).send({from: user1.address});
        } catch(err) {
            assert(err);
            return;
        }
        assert(false); 
    });

    it('Valid car rental Audi', async() => {
        await contract.methods.rentCar(Audi_address).send({
            from: user0.address,
            gas: MAX_GAS
        });
        const updatedRenter = await contract.methods.getRenter(user0.address).call();
        const car = await contract.methods.getCar(Audi_address).call();
        
        assert.equal(updatedRenter.car, Audi_address);
        assert.equal(car.renter, user0.address);
    });

    it('End rental BMW by owner', async() => {
        await contract.events.E_endRent()
        .on('data', (event) => {
            console.log("Event happened",event.returnValues); // same results as the optional callback above
        }).on('changed', (event) => {
            console.log("Event changed:",event);
        }).on('error', (error) => {
            console.error("Error for event", error);
        });
        await contract.methods.rentCar(BMW_address).send({
            from:user2.address,
            gas: MAX_GAS
        });

        const ownerBefore = await contract.methods.getOwner(user0.address).call();
        const renterBefore = await contract.methods.getRenter(user2.address).call();
  
        await advanceTimeAndBlock(86400);
        await contract.methods.endRentCar(BMW_address).send({from:user0.address});

        const renterAfter = await contract.methods.getRenter(user2.address).call();
        const ownerAfter = await contract.methods.getOwner(user0.address).call();

        assert(ownerAfter.balance - ownerBefore.balance > web3.utils.toWei('0.9','ether'));
        assert(renterBefore.balance - renterAfter.balance > web3.utils.toWei('0.9','ether'));
    });
    
    it('End rental BMW by car', async() => {
        await contract.methods.rentCar(BMW_address).send({
            from:user2.address,
            gas: MAX_GAS
        });
        const ownerBefore = await contract.methods.getOwner(user0.address).call();
        const renterBefore = await contract.methods.getRenter(user2.address).call();
  
        await advanceTimeAndBlock(86400);
        await contract.methods.endRentCar(BMW_address).send({
            from: BMW_address ,
            gas: MAX_GAS
        });

        const renterAfter = await contract.methods.getRenter(user2.address).call();
        const ownerAfter = await contract.methods.getOwner(user0.address).call();

        assert(ownerAfter.balance - ownerBefore.balance > web3.utils.toWei('0.9','ether'));
        assert(renterBefore.balance - renterAfter.balance > web3.utils.toWei('0.9','ether'));
    });
    
    it('End rental BMW by renter', async() => {
        await contract.methods.rentCar(BMW_address).send({
            from:user2.address,
            gas: MAX_GAS
        });        
        const ownerBefore = await contract.methods.getOwner(user0.address).call();
        const renterBefore = await contract.methods.getRenter(user2.address).call();
        
        await advanceTimeAndBlock(86400);
        await contract.methods.endRentCar(BMW_address).send({
            from:user2.address,
            gas: MAX_GAS
        });
        
        const renterAfter = await contract.methods.getRenter(user2.address).call();
        const ownerAfter = await contract.methods.getOwner(user0.address).call();

        assert(ownerAfter.balance - ownerBefore.balance > web3.utils.toWei('0.9','ether'));
        assert(renterBefore.balance - renterAfter.balance > web3.utils.toWei('0.9','ether'));
    });

    it('withdraw balance owner', async() =>{
        var balance = await web3.eth.getBalance(accounts[0]);
        console.log('Amount of Ether inside account0 after deploying car:', balance);
        await contract.methods.withdrawBalanceOwner().call({from:accounts[0]});
        console.log('Amount of Ether inside account0 after withdrawal:', accounts[0])
        
    });
    
    it('withdraw balance renter', async() =>{
        console.log('Amount of Ether inside account0 after deploying car:', web3.eth.getBalance(accounts[0]))
        await contract.methods.withdrawBalanceRenter().call({from:accounts[0]});
        console.log('Amount of Ether inside account0 after deploying car:', web3.eth.getBalance(accounts[0]))
    });

    it('withdraw balance owner while car lent out', async() =>{
        await contract.methods.rentCar(BMW_address).send({
            from: user1.address,
            gas: MAX_GAS
        });

        try{ 
            await contract.methods.withdrawBalanceOwner().call({from:accounts[0]});
        } catch(err) {
            assert(err);
            return;
        }
        assert(false);
    });
    
    it('withdraw balance renter while driving', async() =>{
        await contract.methods.rentCar(BMW_address).send({
            from: user1.address,
            gas: MAX_GAS
            });

        try{
            await contract.methods.withdrawBalanceRenter().call({from:accounts[1]});
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
        await contract.methods.fundBalanceOwner().send({
            from: accounts[1],
            value: web3.utils.toWei('20','ether'),
            gas: MAX_GAS
        });
        const balanceAfter = await contract.methods.getBalanceOwner().call({from:accounts[1]});
        assert(balanceAfter-balanceBefore == web3.utils.toWei('20', 'ether'));
    });
    
    it('underflow', async() =>{
        const balanceBefore = await contract.methods.getBalanceOwner().call({from:accounts[1]});
        console.log('Balance Before:', balanceBefore)
        await contract.methods.rentCar(Audi_address).send({
            from:accounts[1],
            gas: MAX_GAS
        });

        await advanceTimeAndBlock(86400);

        await contract.methods.endRentCar(Audi_address).send({
            from:accounts[1],
            gas: MAX_GAS
        });
                
        const balanceAfter = await contract.methods.getBalanceOwner().call({from:accounts[1]});
        console.log('Balance After:', balanceAfter);
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
