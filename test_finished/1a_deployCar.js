const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require ('web3');
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const web3 = new Web3(ganache.provider());

const {abi, evm} = require('../compile');
const MAX_GAS = '6721975'

let contract;     //Holds instance of our contract
let accounts;       //Holds instances of all accounts

//Variables to initiate basic car
let location = 'Berendrecht';
let identifier = '001';
let ownerName = 'Rita';
let accessToken = '0x0000';
let pricePerBlock = 2;

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

    it('deploy car 1', async() => {
        await contract.methods.deployCar(location,identifier,ownerName,accessToken,pricePerBlock).send({
            from: accounts[0],
            value: web3.utils.toWei('5','ether'),
            gas: MAX_GAS
        });

        const BMW = await contract.methods.getCar(identifier).call();
        const Rita = await contract.methods.getOwner(BMW.owner).call();

        assert.equal(BMW.owner, accounts[0]);
        assert.equal(BMW.renter,'0x0000000000000000000000000000000000000000');
        assert.equal(BMW.carHW,'0x0000000000000000000000000000000000000000');
        assert.equal(BMW.location,location);
        assert.equal(BMW.contractStep,0);
        assert.equal(BMW.pricePerBlock, pricePerBlock);
        assert.equal(BMW.accessToken, accessToken);
        assert.equal(BMW.location, location);

        assert.equal(BMW.owner, Rita.addr);
        assert.equal(Rita.balance, web3.utils.toWei('5','ether'));
        assert.equal(Rita.name,ownerName);
        assert.equal(Rita.carIdentifier, BMW.identifier);    
    });

    it('car already deployed', async() => {
        try {
            await contract.methods.deployCar(location,identifier,'Bernie',accessToken,pricePerBlock).send({
            from: accounts[1],
            value: web3.utils.toWei('6','ether'),
            gas: MAX_GAS
            });
            assert(false);

        }catch(err) {
            assert(err);
        };    
    });

    it('not enough deposit', async() => {
        try {await contract.methods.deployCar('Schuur','002','Bernie','0x0001',4).send({
            from: accounts[1],
            value: web3.utils.toWei('4.9','ether'),
            gas: MAX_GAS
        });
        assert(false); 
        } catch (err){
            assert(err);
        }
    
    });

    it('deploy car 2', async() => {
        await contract.methods.deployCar(location,'002','Bernard','0xaaaa',3).send({
            from: accounts[1],
            value: web3.utils.toWei('10','ether'),
            gas: MAX_GAS
        });

        const Audi = await contract.methods.getCar('002').call();
        const Bernard = await contract.methods.getOwner(Audi.owner).call();

        assert.equal(Audi.owner, accounts[1]);
        assert.equal(Audi.renter,'0x0000000000000000000000000000000000000000');
        assert.equal(Audi.carHW,'0x0000000000000000000000000000000000000000');
        assert.equal(Audi.location,location);
        assert.equal(Audi.contractStep,0);
        assert.equal(Audi.pricePerBlock, 3);
        assert.equal(Audi.accessToken, '0xaaaa');
        assert.equal(Audi.location, location);
    
        assert.equal(Audi.owner, Bernard.addr);
        assert.equal(Bernard.balance, web3.utils.toWei('10','ether'));
        assert.equal(Bernard.name,'Bernard');
        assert.equal(Bernard.carIdentifier, Audi.identifier);    
    });

    it('deploy car 3', async() => {
        await contract.methods.deployCar(location,'003','David','0xffff',6).send({
            from: accounts[2],
            value: web3.utils.toWei('15','ether'),
            gas: MAX_GAS
        });

        const Tesla = await contract.methods.getCar('003').call();
        const David = await contract.methods.getOwner(Tesla.owner).call();

        assert.equal(Tesla.owner, accounts[2]);
        assert.equal(Tesla.renter,'0x0000000000000000000000000000000000000000');
        assert.equal(Tesla.carHW,'0x0000000000000000000000000000000000000000');
        assert.equal(Tesla.location,location);
        assert.equal(Tesla.contractStep,0);
        assert.equal(Tesla.pricePerBlock, 6);
        assert.equal(Tesla.accessToken, '0xffff');
        assert.equal(Tesla.location, location);

        assert.equal(Tesla.owner, David.addr);
        assert.equal(David.balance, web3.utils.toWei('15','ether'));
        assert.equal(David.name,'David');
        assert.equal(David.carIdentifier, Tesla.identifier);    
    });
    
});