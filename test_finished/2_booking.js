const assert = require('assert');
const ganache = require('ganache-cli');
const EthCrypto = require('eth-crypto');
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

beforeEach(async() => {

    web3.setProvider(ganache.provider({
        accounts: ganacheAccounts
    }));
    accounts = await web3.eth.getAccounts();
    contract = await new web3.eth.Contract(abi)
        .deploy({data: evm.bytecode['object']})
        .send({ from: accounts[0], gas: MAX_GAS});

    contract.events.E_carAvailable({},
        function(error, event){
            carAvailable = event.returnValues;
            console.log("Available Car Address:", event.returnValues.addr);
            console.log("Available Car Token:", event.returnValues.token);
            console.log("Available Car Price:", event.returnValues.location);
            console.log("Available Car Location:", event.returnValues.price);
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
});

describe('dPACE Deployment', () => {
    it('deploys a contract', () => {
        assert.ok(contract.options.address);
        for (let i = 0; i<10;i++){
            assert.equal(accounts[0], gen_accounts[0].address);
        }
    });
    
    it('Renter initiates booking', async () => {
        contract.events.E_renterBooking({},
            function(error, event){
                newEvent = event;
                console.log("Renter has booked:", event.returnValues);
            }
        );
        const car = gen_accounts[9];
        const renter = gen_accounts[1];
        // Car & Renter generate hashlocks during offline communication
        let hashlock = generateHashlock(renter.address,car);
        const secretLink = web3.utils.soliditySha3(carAvailable.token);
        
        await contract.methods.renterBooking(
            car.address,
            secretLink,
            hashlock.vrs.r,
            hashlock.vrs.s,
            hashlock.vrs.v,
            hashlock.message).send({
                from: accounts[1],
                gas: MAX_GAS
            });
        assert.equal(await contract.methods.renter_state(accounts[1]).call(),2);
        //Car accepts booking
        contract.events.E_carBooking({},
            function(error, event){
                newEvent = event;
                console.log("Car is booked:", event.returnValues);
            }
        );
        //hashlock of renter
        hashlock = generateHashlock(car.address,renter);

        await contract.methods.carBooking(
            renter.address,
            hashlock.vrs.r,
            hashlock.vrs.s,
            hashlock.vrs.v,
            hashlock.message).send({
                from: accounts[9],
                gas: MAX_GAS
            });
    
        assert.equal(await contract.methods.car_state(accounts[9]).call(),2);

    });
});

function generateHashlock(address,sender){
    const prn = new Prng().random;
    let hashlock = web3.utils.soliditySha3(prn);
    const message = {
        'destination': address,
        'hashlock': true,
        'content': hashlock
    }
    const encodedMessage = web3.eth.abi.encodeParameters(
        ['address','bool', 'uint'],
        [message.destination ,message.hashlock,message.content]
    );
    console.log("Encodeed Message: ", encodedMessage);
    console.log("Message: ", message);
    const signature = EthCrypto.sign(sender.privateKey, web3.utils.soliditySha3(encodedMessage));
    const vrs = EthCrypto.vrs.fromString(signature);
    return {
        'vrs': vrs,
        'message': message
    }
}
/*hash:
0xdfb2cbfa50fd6410161549d21085946753a285a03e938eeee912205c12a71d39
signature:
0x317a73a76b11a13255713ace8d0b4d7c3fc8d454723de9e66d8dddcb166215b90d9c7a07aecc8882a405108bf9478556ebdceb8f685d6cab1ab417705aa375b91b*/