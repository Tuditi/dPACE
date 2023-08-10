const Web3 = require('web3');
const web3 = new Web3();
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.question('Input hex value:', (answer) => {
    console.log(web3.utils.hexToNumberString(answer));
  
    rl.close();
  });