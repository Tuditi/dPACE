const assert = require("assert");
const Web3 = require("web3");
const Hasher =  require('../ownSignature/lib/hasher.js');
const BN = require('bn.js');

const Signature = artifacts.require("Signature");
const web3 = new Web3();
const MAX_GAS = '6721975';

const data = [0,"105284528608540558694214425881153086411029979414889393160458771623878645487184","80445768344767687293813562687811261839650970665975442985043312519548221102519","70155562988372923231258439146613290733563890923360024624455370520829594666303","69185549008795371571497417863915520501490144534398064477271263354210656007425","81030867730549743455395857017564887322492161501194844674184259322255636378731","72202459053412226095683909948010709920369382352867928058510655494216431711384","40775730204573062582418038031024953645024375691427270367638915663033772425349"]

var ring_signature;
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

contract('Ring Signature', async accounts => {
    it('deploys a contract', async() => {
        let contract = await Signature.deployed();
        assert.ok(contract.address);
    });

    it('Check Function Evaluation', async() => {
        let hasher = new Hasher();
        let contract = await Signature.deployed();
        await contract.EvaluateCurve(1);
        
        let result = await contract.getEvaluate.call();
        console.log("Check Resul",result);
        console.log('JS result:',hasher.evaluate_curve(1))

    });

    it('Check Hash Point', async() => {
        let hasher = new Hasher();
        let contract = await Signature.deployed();
        await contract.HashPoint([1,2]);

        let point_sol = await contract.getHashPoint.call();
        let point_js = hasher.hash_point({x: 1, y:2});
        /*console.log("X value SOL:",point_sol[0].words);
        console.log("X value JS:",point_js.x.words);
        console.log("Y value SOL:",point_sol[1].words);
        console.log("Y value JS:",point_js.y.words);*/

    });

    it('Check Hash Function', async()=> {
        let hasher = new Hasher()
        let contract = await Signature.deployed();
    });

    

/*    it('Generate Ring Signature', async() =>{
        let signature = await Signature.deployed();
        await debug(signature.RingSign(2, data));
        ring_signature = await signature.getSignature.call();
    });

    it('Verify Ring Signature', async() =>{
        let signature = await Signature.deployed();
        let input = new Array();
        for (let i = 0; i<8; i++){
            input.push(ring_signature[i].toString());
        }
        console.log("Input:",input);
        let verification = await signature.RingVerify(2,input);
        console.log("Verification TX:", verification.logs[0].args);
    })
Returned values:
signature: [ 1390638438710663993255405323439560841386694435713993821283023880735575514600,
            21832140700948873614959210489165846953820190007111093242468843594767281064065,
            12974479643492556522608137173759869703967328029918775421819293627152966380386,
            56928207578540626247867062760050919537951739001604060715434167796546937437714,
            95530499393427221242529996514158922295763779067726638743202622884763073819294,
            81030867730549743455395857017564887322492161501194844674184259322255636378721,
            72202459053412226095683909948010709920369382352867928058510655494216431711384,
            63189838370295122826848751332382324761306038229432874983890937374797064747272,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0 ]*/
    /*it('Check whether hashing passes', async() => {
        let signature = await Signature.deployed();
        let y = await signature.HashPoint([1,2]);
        y = y.logs[0].args;
        let hasher = new Hasher();
        let point = hasher.hash_point({x:1,y:2})
       //Hash not equal
    });
    /*
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
            message,[0,privKey,rand1,rand2,rand3,compressedPK0,compressedPK1,compressedPK2]
        ).call({
            from: accounts[0],
            gas: MAX_GAS
        });
        console.log(ringSignature);
        const verification = await contract.methods.RingVerify(
            message,ringSignature
        ).call({
            from: accounts[0],
            gas: MAX_GAS
        });

        console.log(verification);

    })*/

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