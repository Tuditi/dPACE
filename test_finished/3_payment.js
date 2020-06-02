const assert = require('assert');
const ganache = require('ganache-cli');
const EthCrypto = require('eth-crypto');
const hashjs = require('ethereumjs-abi');
const Web3 = require ('web3');
const Prng = require('../ownSignature/lib/prng')
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const web3 = new Web3(ganache.provider());
require('events').EventEmitter.defaultMaxListeners = 100;

const {abi, evm} = require('../compile');
const MAX_GAS = '6721975'

let contract;     //Holds instance of our contract
let accounts;     //Holds instances of all accounts (0-4: renters, 5-9: cars)
let carAvailable;   

//Generates ganache accounts
let gen_accounts = new Array();
let ganacheAccounts = new Array();
let account;
for (let i = 0; i<10; i++){
    account = EthCrypto.createIdentity()
    gen_accounts.push(account);
    ganacheAccounts.push({
        secretKey: account.privateKey,
        balance: web3.utils.toWei('100', 'ether')
    })
}

//Randomly generated RSP address
const RSPAddress = 0x1900A200412d6608BaD736db62Ba3352b1a661F2;
const publicKeyRSP = '86b41d0c97dd302e7df473f243766ef803afabd2c93ddc9f670e059494eb66587bf3759c938d2c73f132697fd824496be4001849c3dff06f569de3b7bd63d491';
const privateKeyRSP = 'ff6415f9fd0b8d9b3712843c53048b27a51171ce713517f42f4820e74310f614';


//Defines PPC & performs signature by the RSP
const proofOfRegistration = "David De Troch's driver's license";
const ppc = web3.utils.soliditySha3(proofOfRegistration);
const signature = EthCrypto.sign(privateKeyRSP,ppc);
const vrs = EthCrypto.vrs.fromString(signature);

//Defines Car Details
const details = web3.utils.soliditySha3("BMW");
const token = web3.utils.soliditySha3(Math.floor((Math.random() * 10) + 1));
const location = "Pentagon";

//Define Interacting Parties
const car = gen_accounts[9];
const renter = gen_accounts[1];
// Car & Renter generate hashlocks during offline communication
const hashlockRenter = generateHashlock(renter.address,car);
const hashlockCar = generateHashlock(car.address,renter);

beforeEach(async() => {
    web3.setProvider(ganache.provider({
        accounts: ganacheAccounts
    }));
    accounts = await web3.eth.getAccounts();
    contract = await new web3.eth.Contract(abi)
        .deploy({data: evm.bytecode['object']})
        .send({ from: accounts[0], gas: MAX_GAS});
    //Event listener to get AT:
    contract.events.E_carAvailable({},
        function(error, event){
            carAvailable = event.returnValues;
        }
    );

    await contract.methods.deployRenter(ppc, vrs.r, vrs.s, vrs.v).send({
        from: accounts[1],
        value: web3.utils.toWei('20','ether'),
        gas: MAX_GAS
    });

    await contract.methods.deployCar(accounts[9], details, web3.utils.toWei('0.000011574','ether')).send({
        from: accounts[2],
        value: web3.utils.toWei('6','ether'),
        gas: MAX_GAS
    });

    await contract.methods.validateCar(token, location).send({
        from: accounts[9],
        gas: MAX_GAS
    });

    const secretLink = web3.utils.soliditySha3(carAvailable.token);
    await contract.methods.renterBooking(
        car.address,
        secretLink,
        hashlockRenter.vrs.r,
        hashlockRenter.vrs.s,
        hashlockRenter.vrs.v,
        hashlockRenter.message).estimateGas({
        from: accounts[1],
        gas: 5000000}, function(error, gasAmount){
            console.log('Gas Amount Renter Booking: ', gasAmount);
    });
    await contract.methods.renterBooking(
        car.address,
        secretLink,
        hashlockRenter.vrs.r,
        hashlockRenter.vrs.s,
        hashlockRenter.vrs.v,
        hashlockRenter.message).send({
            from: accounts[1],
            gas: MAX_GAS
        });

    
});

describe('dPACE Deployment', () => {
    it('deploys a contract', () => {
        assert.ok(contract.options.address);
        for (let i = 0; i<10;i++){
            assert.equal(accounts[0], gen_accounts[0].address);
        }
    });

    it('Car Submits Fee', async () => {
        await contract.methods.carBooking(
            renter.address,
            hashlockCar.vrs.r,
            hashlockCar.vrs.s,
            hashlockCar.vrs.v,
            hashlockCar.message).estimateGas({
            from: accounts[9],
            gas: 5000000}, function(error, gasAmount){
                console.log('Gas Amount Car Booking: ', gasAmount);
        });

        await contract.methods.carBooking(
            renter.address,
            hashlockCar.vrs.r,
            hashlockCar.vrs.s,
            hashlockCar.vrs.v,
            hashlockCar.message).send({
                from: accounts[9],
                gas: MAX_GAS
            });    
        contract.events.E_carPaid({},
            function(error, event){
                eventPaid = event.returnValues;
                console.log("Car was paid:", eventPaid);
            }
        );
        //Generate new token
        const newToken = web3.utils.soliditySha3(Math.floor((Math.random() * 10) + 1));
        const newLocation = "Washington";
        const signedTime = signTime(car.address,renter);
        console.log("Balance Car before", await contract.methods.car_balance(accounts[9]).call());

        await contract.methods.carPayment(
            '0x'+hashlockCar.prn,
            '0x'+hashlockCar.prn,
            newToken,
            newLocation,
            signedTime.vrs.r,
            signedTime.vrs.s,
            signedTime.vrs.v,
            signedTime.message
        ).estimateGas({
            from: accounts[9],
            gas: 5000000}, function(error, gasAmount){
                console.log('Gas Amount Car Payment: ', gasAmount);
        });

        await contract.methods.carPayment(
            '0x'+hashlockCar.prn,
            '0x'+hashlockCar.prn,
            newToken,
            newLocation,
            signedTime.vrs.r,
            signedTime.vrs.s,
            signedTime.vrs.v,
            signedTime.message
        ).send({
            from: accounts[9],
            gas: MAX_GAS
        })
        console.log("Balance Car After", await contract.methods.car_balance(accounts[9]).call());
        //Renter pays
        const signedFee = signFee(eventPaid.fee,renter.address,car);
        console.log("Balance Renter before", await contract.methods.renter_balance(accounts[1]).call());
        await contract.methods.renterPayment(
            '0x'+hashlockRenter.prn,
            signedFee.vrs.r,
            signedFee.vrs.s,
            signedFee.vrs.v,
            signedFee.message
        ).estimateGas({
            from: accounts[1],
            gas: 5000000}, function(error, gasAmount){
                console.log('Gas Amount Renter Payment: ', gasAmount);
        });

        await contract.methods.renterPayment(
            '0x'+hashlockRenter.prn,
            signedFee.vrs.r,
            signedFee.vrs.s,
            signedFee.vrs.v,
            signedFee.message
        ).send({
            from: accounts[1],
            gas: MAX_GAS
        })
        console.log("Balance Renter after", await contract.methods.renter_balance(accounts[1]).call());
        assert.equal(await contract.methods.renter_state(accounts[1]).call(), 1);
    });
});

function generateHashlock(address,sender){
    const prn = new Prng().random;
    let hashlock = hashjs.soliditySHA3(["bytes32"],['0x'+prn]).toString('hex');
    hashlock = web3.utils.hexToNumberString('0x'+hashlock);
    const message = {
        'destination': address,
        'hashlock': true,
        'content': hashlock
    }
    const encodedMessage = web3.eth.abi.encodeParameters(
        ['address','bool', 'uint'],
        [message.destination ,message.hashlock,message.content]
    );
    const signature = EthCrypto.sign(sender.privateKey, web3.utils.soliditySha3(encodedMessage));
    const vrs = EthCrypto.vrs.fromString(signature);
    return {
        'vrs': vrs,
        'message': message,
        'prn': prn
    }
}

function signTime(address, sender){
    const timestamp = new Date().getTime();
    const message = {
        'destination': address,
        'hashlock': false,
        'content': Math.floor(timestamp/1000)+43200
    }
    const encodedMessage = web3.eth.abi.encodeParameters(
        ['address','bool', 'uint'],
        [message.destination ,message.hashlock,message.content]
    );
    const signature = EthCrypto.sign(sender.privateKey, web3.utils.soliditySha3(encodedMessage));
    const vrs = EthCrypto.vrs.fromString(signature);
    return {
        'vrs': vrs,
        'message': message,
    }
}

function signFee(fee,address, sender){
    const message = {
        'destination': address,
        'hashlock': false,
        'content': fee
    }
    const encodedMessage = web3.eth.abi.encodeParameters(
        ['address','bool', 'uint'],
        [message.destination ,message.hashlock,message.content]
    );
    const signature = EthCrypto.sign(sender.privateKey, web3.utils.soliditySha3(encodedMessage));
    const vrs = EthCrypto.vrs.fromString(signature);
    return {
        'vrs': vrs,
        'message': message,
    }
}

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
