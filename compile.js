const path = require('path');
const solc = require('solc');
const fs = require('fs-extra');

const buildPath = path.resolve(__dirname, 'build');
fs.removeSync(buildPath);

const contractPath = path.resolve(__dirname,'contracts');
var sources = new Array();

fs.readdir(contractPath, (err, files) => {
    if (err) {
      console.error("Could not list the directory.", err);
      process.exit(1);
    } else {
        files.forEach( (file,_) => {
            sources.push(fs.readFileSync(contractPath + '/' + file,'UTF-8'));
        });
    };
});

var output;
fs.ensureDirSync(buildPath);

//Timeout is used, since JS fires off a callback upon fs.readdir, which takes some time to complete. 
setTimeout(() => {
    const input = {
        language: "Solidity",
        sources: {
            "PKI.sol": {
                content: sources[0]
            },
            "Verify_deployRenter.sol": {
                content: sources[1]
            },
            "Verify_renterBooking.sol": {
                content: sources[2]
            },
            "Verify_renterPayment.sol": {
                content: sources[3]
            },
            "dPACE.sol": {
                content: sources[4]
            },        
        },settings: {
            outputSelection: {
                "*": {
                    "*": ["abi", "evm.bytecode.object"]
                }
            }
        }
    };
    output = JSON.parse(solc.compile(JSON.stringify(input),
        { import: findImports })).contracts;
    
    for (let contract in output){
        //If library, they have to be kept separately
        if (contract === 'verify_libs.sol'){
            for (let lib in output[contract]){
                fs.outputJsonSync(
                    path.resolve(buildPath, lib + '.json'),
                    output[contract]);
            }
        }
        else { 
            fs.outputJsonSync(
            path.resolve(buildPath, contract.slice(0,-4) + '.json'),
            output[contract]
            );
        }}
    },       
    100
);




function findImports(path) {
    return {
        contents:
            fs.readFileSync(contractPath + '/' + path,'utf8')
    };
}