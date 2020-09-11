const assert = require('assert');
const ganache = require('ganache-cli');
const EthCrypto = require('eth-crypto');
const Web3 = require ('web3');
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const web3 = new Web3(ganache.provider());
require('events').EventEmitter.defaultMaxListeners = 100;

const {abi, evm} = require('./CarSharing/Thesis/compile');
const MAX_GAS = '6721975'

let contract;     //Holds instance of our contract
let accounts;       //Holds instances of all accounts (0-4: renters, 5-9: cars)

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
    web3.setProvider(ganache.provider());
    accounts = await web3.eth.getAccounts();
    contract = await new web3.eth.Contract(abi)
        .deploy({data: evm.bytecode['object']})
        .send({ from: accounts[0], gas: MAX_GAS});
});

describe('dPACE Deployment', () => {
    it('deploys a contract', () => {
        assert.ok(contract.options.address);
    });

    it('Period Set', async () => {
        const PERIOD = await contract.methods.PERIOD().call();
        assert.equal(86400, PERIOD);
    });

    it('Deposit Set', async () => {
        const DEPOSIT = await contract.methods.DEPOSIT().call();
        assert.equal(web3.utils.toWei('0.5','ether'), DEPOSIT);
    });

    it('Registration Service Set', async () => {
        const RS = await contract.methods.REGISTRATION_SERVICE().call();
        assert.equal(RS,RSPAddress);
    });

    it('Deploy Renter', async () => {
        contract.events.E_deployRenter({},
            function(error, event){
                newEvent = event;
                console.log("New Renter:", event.returnValues);
            }
        );
        console.log("ppc:",ppc);
        console.log("vrs",vrs);
        await contract.methods.deployRenter(ppc, vrs.r, vrs.s, vrs.v).send({
            from: accounts[1],
            value: web3.utils.toWei('20','ether'),
            gas: MAX_GAS
        });

        assert.equal(await contract.methods.renter_ppc(accounts[1]).call(),ppc);
    });

    it('Deploy Car', async() => {
        contract.events.E_deployCar({},
            function(error, event){
                newEvent = event.returnValues;
                console.log("Car Deployed:", event.returnValues);
            }
        );

        console.log("accounts: INSERT YOURSELF");
        console.log("details:",details);
        console.log("price:", web3.utils.toWei('0.000011574','ether'))

        await contract.methods.deployCar(accounts[9], details, web3.utils.toWei('0.000011574','ether')).send({
            from: accounts[2],
            value: web3.utils.toWei('6','ether'),
            gas: MAX_GAS
        });

        assert.equal(newEvent.addr,accounts[9]);
        
    });

    it('Validate Car', async() =>{
        contract.events.E_carAvailable({},
            function(error, event){
                newEvent = event.returnValues;
                console.log("Available Car:", event.returnValues);
            }
        );
        await contract.methods.deployCar(accounts[9], details, web3.utils.toWei('0.000011574','ether')).send({
            from: accounts[2],
            value: web3.utils.toWei('6','ether'),
            gas: MAX_GAS
        });

        console.log("accounts: INSERT YOURSELF");
        console.log("token:", token);
        console.log("price:", location)

        await contract.methods.validateCar(token, location).send({
            from: accounts[9],
            gas: MAX_GAS
        });
        assert.equal(newEvent.price,web3.utils.toWei('0.000011574','ether'));
    });
});