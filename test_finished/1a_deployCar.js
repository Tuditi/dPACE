const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require ('web3');
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const web3 = new Web3(ganache.provider());
require('events').EventEmitter.defaultMaxListeners = 100;


const {abi, evm} = require('../compile');
const MAX_GAS = '6721975'

let contract;     //Holds instance of our contract
let accounts;       //Holds instances of all accounts

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

beforeEach(async() => {
    accounts = await web3.eth.getAccounts();
    contract = await new web3.eth.Contract(abi)
        .deploy({data: evm.bytecode['object']})
        .send({ from: accounts[0], gas: MAX_GAS});
});

describe('Car Deployment', () => {
    it('deploys a contract', () => {
        assert.ok(contract.options.address);
    });

    /*it('deploy car 1', async() => {
        await contract.methods.deployCar(BMW_address,BMW_accessToken,BMW_location,BMW_details,2,'Rita').send({
            from: accounts[0],
            value: web3.utils.toWei('5','ether'),
            gas: MAX_GAS
        });

        const BMW = await contract.methods.getCar(BMW_address).call();
        const Rita = await contract.methods.getOwner(accounts[0]).call();
        
        assert.equal(BMW.owner, accounts[0]);
        assert.equal(BMW.renter,'0x0000000000000000000000000000000000000000');
        assert.equal(BMW.carHW, BMW_address);
        assert.equal(BMW.accessToken, BMW_accessToken);
        assert.equal(BMW.location, BMW_location);
        assert.equal(BMW.available, true);
        assert.equal(BMW.price, 2);
        assert.equal(BMW.endTime, 0);

        assert.equal(BMW.owner, Rita.addr);
        assert.equal(Rita.balance, web3.utils.toWei('5','ether'));
        assert.equal(Rita.name,'Rita');
    });

    it('car already deployed', async() => {
        await contract.methods.deployCar(BMW_address,BMW_accessToken,BMW_location,BMW_details,2,'Rita').send({
            from: accounts[0],
            value: web3.utils.toWei('5','ether'),
            gas: MAX_GAS
        });
        
        try {
            await contract.methods.deployCar(BMW_address,BMW_accessToken,BMW_location,BMW_details,2,'Bernard').send({
            from: accounts[1],
            value: web3.utils.toWei('6','ether'),
            gas: MAX_GAS
            });

        }catch(err) {
            assert(err);
            return;
        };
        assert(false);
    });

    it('not enough deposit', async() => {
        try {await contract.methods.deployCar(Audi_address,Audi_accessToken,Audi_location,Audi_details,2,'Bernard').send({
            from: accounts[1],
            value: web3.utils.toWei('4.9','ether'),
            gas: MAX_GAS
        });
        } catch (err){
            assert(err);
            return;
        }
        assert(false);
    });

    it('deploy car 2', async() => {
        await contract.methods.deployCar(Audi_address,Audi_accessToken,Audi_location,Audi_details,2,'Bernard').send({
            from: accounts[1],
            value: web3.utils.toWei('10','ether'),
            gas: MAX_GAS
        });

        const Audi = await contract.methods.getCar(Audi_address).call();
        const Bernard = await contract.methods.getOwner(Audi.owner).call();

        assert.equal(Audi.owner, accounts[1]);
        assert.equal(Audi.renter,'0x0000000000000000000000000000000000000000');
        assert.equal(Audi.carHW,Audi_address);
        assert.equal(Audi.accessToken, Audi_accessToken);
        assert.equal(Audi.location, Audi_location);
        assert.equal(Audi.available, true);
        assert.equal(Audi.price, 2);
        assert.equal(Audi.endTime, 0);

        assert.equal(Audi.owner, Bernard.addr);
        assert.equal(Bernard.balance, web3.utils.toWei('10','ether'));
        assert.equal(Bernard.name,'Bernard');
    });*/
});