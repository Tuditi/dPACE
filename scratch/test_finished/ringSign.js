const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require ('web3');
require('events').EventEmitter.defaultMaxListeners = 100;
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const web3 = new Web3(ganache.provider());
//To generate signatures
const Prng = require('../ownSignature/lib/prng.js');
const Hasher = require('../ownSignature/lib/hasher.js');

//To validate signature
const EthCrypto = require('eth-crypto');

//Variables to initiate Mercedes
const Mercedes = EthCrypto.createIdentity();
const Audi = EthCrypto.createIdentity();
const BMW = EthCrypto.createIdentity();

//=== RingSignature ===
    //Inputs:
    //  message (RingMessage) - to be signed by the ring signature
    //  data (uint256[2*N+2]) - required data to form the signature where N is the number of Public Keys (ring size)
    //      data[0] - index from 0 to (N-1) specifying which Public Key has a known private key
    //      data[1] - corresponding private key for PublicKey[k]
    //      data[2   ... 2+(N-1)] - Random Numbers - total of N random numbers
    //      data[2+N ... 2*N+1  ] - Public Keys (compressed) - total of N Public Keys
    //      e.g. N=3; data = {k, PrivateKey_k, random0, random1, random2, PubKey0, PubKey1, PubKey2 }
    //

const message = "105284528608540558694214425881153086411029979414889393160458771623878645487184";


const {abi, evm} = require('../compile');
const MAX_GAS = '6721975';

let contract;     //Holds instance of our contract
let accounts;

//Global variables:
var compressedPK0;

beforeEach(async() => {
    accounts = await web3.eth.getAccounts();
    contract = await new web3.eth.Contract(abi)
        .deploy({data: evm.bytecode['object']})
        .send({ from: accounts[0], gas: MAX_GAS});
});

describe('Ring Signature', () => {
    it('deploys a contract', () => {
        assert.ok(contract.options.address);
    });

    it('hash point', async() => {
        let hasher = new Hasher();
    })
    
    it('Correct point compression and expansion', async() =>{
        //Mercedes
        let Pka1 = web3.utils.hexToNumberString('0x'+Mercedes.publicKey.slice(0,64));
        let Pka2 = web3.utils.hexToNumberString('0x'+Mercedes.publicKey.slice(64));
        compressedPK0 = await contract.methods.CompressPoint([Pka1,Pka2]).call({
            from: accounts[0],
            gas: MAX_GAS
        });
        let check_expandPoint = await contract.methods.ExpandPoint(compressedPK0).call({
            from: accounts[0],
            gas: MAX_GAS
        });

        console.log(Pka1);
        console.log("Proper slicing 1? ==> ",'0x'+Mercedes.publicKey.slice(0,64))
        console.log("Proper slicing 2? ==> ",Pka1)
        console.log("Transformation? ==> ",compressedPK0);
        assert.equal(Pka1,check_expandPoint[0]);
        console.log('----------------------------------------------')
        assert.equal(Pka2,check_expandPoint[1]);
        

    })
});
    /*
    it('generates a ring signature', async() =>{
        
        //BMW
        let Pkb1 = web3.utils.hexToNumberString('0x'+Audi.publicKey.slice(0,64));
        let Pkb2 = web3.utils.hexToNumberString('0x'+Audi.publicKey.slice(64));
        const compressedPK1 = await contract.methods.CompressPoint([Pkb1,Pkb2]).call({
            from: accounts[0],
            gas: MAX_GAS
        });
        //Audi
        let Pkc1 = web3.utils.hexToNumberString('0x'+BMW.publicKey.slice(0,64));
        let Pkc2 = web3.utils.hexToNumberString('0x'+BMW.publicKey.slice(0,64));
        const compressedPK2 = await contract.methods.CompressPoint([Pkc1,Pkc2]).call({
            from: accounts[0],
            gas: MAX_GAS
        });

        const privKey = web3.utils.hexToNumberString(Mercedes.privateKey);


        let rand1 = web3.utils.hexToNumberString('0x'+new Prng().random);
        let rand2 = web3.utils.hexToNumberString('0x'+new Prng().random);
        let rand3 = web3.utils.hexToNumberString('0x'+new Prng().random);
        
        console.log('k:',0);
        console.log('privKey:',privKey);
        console.log('rand1:',rand1);
        console.log('rand2:',rand2);
        console.log('rand3:',rand3);
        console.log('compressedPK0:',compressedPK0);
        console.log('compressedPK1:',compressedPK1);
        console.log('compressedPK2:',compressedPK2);

        let data = [0,privKey,rand1,rand2,rand3,compressedPK0,compressedPK1,compressedPK2];
        
        
        const ringSignature = await contract.methods.RingSign(
            2,data
        ).call({
            from: accounts[0],
            gas: MAX_GAS
        });
        console.log("Ring Signature:",ringSignature.slice(0,data.length));

        const verification = await contract.methods.RingVerify(
            2,ringSignature.slice(0,8)
        ).call({
            from: accounts[0],
            gas: MAX_GAS
        });

        console.log(verification);

    })




/* KLADBLOK


const Merc_address = '0x2a63100f352FC1005Ccd80aFe8eB5F3E5BDFbf3d';
const Merc_privateKey = '0xe8c4ee72dec852d020f3f04a593b12c6f2dd2421bfde6e025956c59840c79650';
const Merc_publicKey = 'b325d889d122fb4a3ed05d217df5d44444ad699226df7e46b317c65bfeaf346b4d2ae9da143ea1e880080e247e563a8969c8e0f111b655d5ede50b74060749da';


nonce = "39648619922660478850978630884800282150490178423736238046076438152587414972135"
data = [0,"105284528608540558694214425881153086411029979414889393160458771623878645487184","113621781303855251557627911988579659885083202662602350329310709487699785964812","56928207578540626247867062760050919537951739001604060715434167796546937437714","95530499393427221242529996514158922295763779067726638743202622884763073819294","81030867730549743455395857017564887322492161501194844674184259322255636378721","72202459053412226095683909948010709920369382352867928058510655494216431711384","63189838370295122826848751332382324761306038229432874983890937374797064747272"]

response: ["1206558198028059218253320549287874064977683470202758856559592061328051120614",
21820231987485768319671630089602074377408583495332182944495032777568230504360",
"3797920073773310492012556907801747613044218402147596035437659748708196841698",
"56928207578540626247867062760050919537951739001604060715434167796546937437714",
"95530499393427221242529996514158922295763779067726638743202622884763073819294",
"81030867730549743455395857017564887322492161501194844674184259322255636378721",
"72202459053412226095683909948010709920369382352867928058510655494216431711384",
"63189838370295122826848751332382324761306038229432874983890937374797064747272",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
*/