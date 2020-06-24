const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
const {abi, evm} = require('./compile');

const provider = new HDWalletProvider(
  'chimney social harsh salad unlock during remove ship suffer ten tattoo agree',
  'https://rinkeby.infura.io/v3/fe9a88120e2e45b8a3ea2b694779d4ff'
);
const web3 = new Web3(provider);

const deploy = async () => {
  const accounts = await web3.eth.getAccounts();

  console.log('Attempting to deploy from account', accounts[0]);

  const result = await new web3.eth.Contract(abi)
    .deploy({ data: evm.bytecode['object']})
    .send({ gas: '6000000', from: accounts[0] });

  console.log('Contract deployed to', result.options.address);
};
deploy();
/*Address: 0xDC549d9Ee75EE78125688c1BC81BdDFc33c73ccD*/