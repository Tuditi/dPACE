const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require ('web3');
require('events').EventEmitter.defaultMaxListeners = 100;
// Initiate a new instance of web3 that uses ganache for local development.
// Once in production, this needs to be changed to test network.
const web3 = new Web3(ganache.provider());
//To generate signatures
const Prng = require('../ownSignature/lib/prng.js');

//To validate signature
const EthCrypto = require('eth-crypto');

//Different users & their keys that are generated:

const user0 = EthCrypto.createIdentity();
const user1 = EthCrypto.createIdentity();
const user2 = EthCrypto.createIdentity();

//Addresses cars:

//Variables to initiate BMW
const BMW_address = '0x5ba7c96BB7707A83AFC2150BfFC81715c3090F04';
const BMW_privateKey = '0x6bc48fee787b0809c3e8fe3fe854e9319ff2d50fbbe5f6d5f1dc3c2602d56ac4';
const BMW_publicKey =   '1fa124c4281fab15064cd5072f60bb6bd925aaa097b22d6fc6c61e019434349802f7898e3849f4ef6aaf8ce052cf6df8ca6ea6ff4072392f6726ae0e8db4760d'

//Variables to initiate Audi
const Audi_address = '0xD21CC33d0CF03675BE89aF7197338a4165751a2E';
const Audi_privateKey = '0x974cc12dfb97b945f97a826ef944abe01303bf3e662f2374bddc17aabf83a708';
const Audi_publicKey = '5a263ed4bc58fa902a71813e851ab2425b8ec696862c16fb3132ba3a5e8e4085abcfcb8ad6c9958d6439812ee2ade7a67eddd76c9829a4eea1f2a5acea996c88';

//Variables to initiate Tesla
const Tesla_address = '0xc18EdD64D4Dc43C4e1AC22A670eF1F482287C39b';
const Tesla_privateKey = '0x8860107c55e633f580c5c20eda7757bcc02c1fa2543a6d619700b492d7b2483c';
const Tesla_publicKey =   '8bb42e5b70bfd1c38b2dfdc5da499fd7b169a1907789383b6ec99c7d8c7ab90802b2109f6c984e009f2863579a4d6a5428d21fa3f881fc952d05be3582e74552';

//Variables to initiate Mercedes

const Merc_address = '0x2a63100f352FC1005Ccd80aFe8eB5F3E5BDFbf3d';
const Merc_privateKey = '0xe8c4ee72dec852d020f3f04a593b12c6f2dd2421bfde6e025956c59840c79650';
const Merc_publicKey = 'b325d889d122fb4a3ed05d217df5d44444ad699226df7e46b317c65bfeaf346b4d2ae9da143ea1e880080e247e563a8969c8e0f111b655d5ede50b74060749da';

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

const message = "David1234";


const {abi, evm} = require('../compile');
const MAX_GAS = '6721975';

let contract;     //Holds instance of our contract
let accounts;



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
    
    it('generates a ring signature', async() =>{
        let Pka1 = web3.utils.hexToNumberString('0xb325d889d122fb4a3ed05d217df5d44444ad699226df7e46b317c65bfeaf3461');
        let Pka2 = web3.utils.hexToNumberString('0x4d2ae9da143ea1e880080e247e563a8969c8e0f111b655d5ede50b74060749d0');
        const compressedPK0 = await contract.methods.CompressPoint([Pka1,Pka2]).call({
            from: accounts[0],
            gas: MAX_GAS
        });

        let Pkb1 = web3.utils.hexToNumberString('0x1fa124c4281fab15064cd5072f60bb6bd925aaa097b22d6fc6c61e0194343498');
        let Pkb2 = web3.utils.hexToNumberString('0x02f7898e3849f4ef6aaf8ce052cf6df8ca6ea6ff4072392f6726ae0e8db4760d');
        const compressedPK1 = await contract.methods.CompressPoint([Pkb1,Pkb2]).call({
            from: accounts[0],
            gas: MAX_GAS
        });

        let Pkc1 = web3.utils.hexToNumberString('0x8bb42e5b70bfd1c38b2dfdc5da499fd7b169a1907789383b6ec99c7d8c7ab908');
        let Pkc2 = web3.utils.hexToNumberString('0x02b2109f6c984e009f2863579a4d6a5428d21fa3f881fc952d05be3582e74552');
        const compressedPK2 = await contract.methods.CompressPoint([Pkc1,Pkc2]).call({
            from: accounts[0],
            gas: MAX_GAS
        });

        const privKey = web3.utils.hexToNumberString(Merc_privateKey);


        let rand0 = web3.utils.hexToNumberString('0x'+new Prng().random);
        let rand1 = web3.utils.hexToNumberString('0x'+new Prng().random);
        let rand2 = web3.utils.hexToNumberString('0x'+new Prng().random);
        let rand3 = web3.utils.hexToNumberString('0x'+new Prng().random);
        
        console.log('k:',0);
        console.log('privKey:',privKey);
        console.log('rand0:',rand0);
        console.log('rand1:',rand1);
        console.log('rand2:',rand2);
        console.log('rand3:',rand3);
        console.log('compressedPK0:',compressedPK0);
        console.log('compressedPK1:',compressedPK1);
        console.log('compressedPK2:',compressedPK2);

        const ringSignature = await contract.methods.RingSign(
            message,rand0,[0,privKey,rand1,rand2,rand3,compressedPK0,compressedPK1,compressedPK2]
            ).call({
                from: accounts[0],
                gas: MAX_GAS
            });
        console.log(ringSignature);

    })

});


/* KLADBLOK
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