const EthCrypto = require('eth-crypto');
const dPACE = artifacts.require("massCarSharing");

//Randomly generated RSP address
const RSPAddress = 0x1900A200412d6608BaD736db62Ba3352b1a661F2;
const publicKeyRSP = '86b41d0c97dd302e7df473f243766ef803afabd2c93ddc9f670e059494eb66587bf3759c938d2c73f132697fd824496be4001849c3dff06f569de3b7bd63d491';
const privateKeyRSP = 'ff6415f9fd0b8d9b3712843c53048b27a51171ce713517f42f4820e74310f614';

const proofOfRegistration = "David De Troch's driver's license";

//Create Cars
const Mercedes = EthCrypto.createIdentity();
const BMW = EthCrypto.createIdentity();
const Tesla = EthCrypto.createIdentity();

const MAX_GAS = '6721975';

function initiateBooking(renter, car){
    const link = EthCrypto.sign(
        renter.privateKey,
        web3.utils.soliditySha3(car.accessToken)
    );
    const sLink = EthCrypto.encryptWithPublicKey(
        car.publicKey,
        link
    );
}
contract('dPACE', async accounts => {

    it("deploys a contract", async() => {
        let contract = await dPACE.deployed();
        assert.ok(contract.address);
    });

    console.log("PHASE 1 ---- DEPLOYMENT")
    it("Deploy Renter:", async() => {
        let contract =  await dPACE.deployed();
        console.log("PPC:", proofOfRegistration);
        
        const ppc = web3.utils.soliditySha3(proofOfRegistration);
        const signature = EthCrypto.sign(privateKeyRSP,ppc);
        const vrs = EthCrypto.vrs.fromString(signature);

        await contract.deployRenter(ppc, vrs.r, vrs.s, vrs.v,{
            from: accounts[1],
            value: web3.utils.toWei('20','ether'),
            gas: MAX_GAS
        });
    });

    it("Deploy Car:", async() => {
        let contract =  await dPACE.deployed();
        const details = web3.utils.soliditySha3("BMW");

        await contract.deployCar(accounts[9], details, web3.utils.toWei('1','ether'),{
            from: accounts[2],
            value: web3.utils.toWei('25','ether'),
            gas: MAX_GAS
        });
    });

    it("Validate Car:", async() => {
        let contract =  await dPACE.deployed();
        
        const token = web3.utils.soliditySha3("BMW Token");
        const location = web3.utils.soliditySha3("Pentagon");
        const BMW = accounts[9];
        await contract.validateCar(token, location,{
            from: BMW,
            gas: MAX_GAS
        });
    });
        /*

    console.log("PHASE 2 -- BOOKING")

    it("Renter books a car:", async() => {

        let contract =  await dPACE.deployed();
        
        const BMW = accounts[9];
        const secretLink;
        const Message;
        const vrs;
        await contract.validateCar(token, location,{
            from: BMW,
            gas: MAX_GAS
        });
    });

    it("Car accepts bookin on-chain", async() => {
        let contract =  await dPACE.deployed();

    });

    console.log("PHASE 3 -- PAYMENT")

    it("Car finalizes booking:", async() => {
        let contract =  await dPACE.deployed();
        
        const token = web3.utils.soliditySha3("BMW Token");
        const location = web3.utils.soliditySha3("Pentagon");
        const BMW = accounts[9];
        await contract.validateCar(token, location,{
            from: BMW,
            gas: MAX_GAS
        });
    });

    it("Renter finalizes booking", async() => {
        let contract =  await dPACE.deployed();

    });*/
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
