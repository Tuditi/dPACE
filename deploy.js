const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
const compiledContract = require('./build/Pairing.json');

const provider = new HDWalletProvider(
  'chimney social harsh salad unlock during remove ship suffer ten tattoo agree',
  'https://rinkeby.infura.io/v3/fe9a88120e2e45b8a3ea2b694779d4ff'
);
const web3 = new Web3(provider);

const deploy = async () => {
  const accounts = await web3.eth.getAccounts();

  console.log('Attempting to deploy from account', accounts[0]);

  const result = await new web3.eth.Contract(compiledContract['Verify_deployRenter'].abi)
    .deploy({ data: compiledContract['Verify_deployRenter'].evm.bytecode['object']})
    .send({ gas: '6000000', from: accounts[0] });

  console.log('Contract deployed to', result.options.address);
};

deploy();
/*
"dPACE: 0x4bcBBc3f3c803fE335b06Bf0d28cE0C490aC6Eb2"
"PKI: 0x894C84732E805d96713bB3845d07d9CA56835913"
"Verify_deployRenter: 0xcADbE1D5c595686451DFeD310F5f5aa979CE9659"
"Verify_renterBooking: 0xBAbFdE34ac107598d99F062dC1209232113B755f"
"verify_renterpayment: 0x27b70b4D718027C8DFeEfD01888AC5CeE58EE0b0"
--------------------------------------------
"Fifth try dPACE: 0x89EA7B3141cCE5999C8FF3c61000b48df41a8FB3"
"Fourth try dPACE: 0x4bcBBc3f3c803fE335b06Bf0d28cE0C490aC6Eb2"
"PKI: 0x32601B41ecB1e4811393eaBa363e68Ef70d34218"
"Verify_deployRenter: 0x3A035a0aF49924cd2897f41a43f87bbF51855eA7"
"Verify_renterBooking: 0x2ff9207097a56Ab942CeaF3D65A762fCbB2899e1"
"verify_renterpayment: 0xf9338e8089f6298f5160b3d3e22fe03fb60e48fe"

Libraries addresses are redeployed each time when deploying a contract. 
Whenever necessary always use the address of the library that gets deployed together
with the smart contract.
"Lib BN256G2: 0x04C6739F71B518FAbBAD4C68e73e2B5F73962fD3"
"Lib Pairing: 0xfdde0D40B13Ac2593CcD8befa67B72Bf26a462e9"
*/