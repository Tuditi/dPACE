const path = require('path');
const solc = require('solc');
const fs = require('fs-extra');

const buildPath = path.resolve(__dirname, 'build');
fs.removeSync(buildPath);

const contractPath = path.resolve(__dirname,'contracts');

console.log(contractPath);
fs.readdir(contractPath, (err, files) => {
    if (err) {
      console.error("Could not list the directory.", err);
      process.exit(1);
    } else {
        var path;
        var source;
        var output = new Array();

        files.forEach( (file,_) => {
            path = path.resolve(__dirname,'contracts', file)
            source = fs.readFileSync(path);
            output.append(solc.compile(JSON.stringify({
                language: "Solidity",
                sources: {
                    ":".concat(file.slice(0,-3)): {
                        content: source
                    }
                },settings: {
                    outputSelection: {
                        "*": {
                            file: ["abi", "evm.bytecode.object"]
                        }
                    }
                }
            })))
        }); 
          
       
    };
});

const dPACEPath = path.resolve(__dirname,'contracts', 'dPACE.sol');
const source = fs.readFileSync(dPACEPath, 'utf8');
const output = solc.compile(JSON.stringify({
    language: "Solidity",
    sources: {
       ":dPACE": {
          content: source
       }
    },settings: {
       outputSelection: {
          "*": {
             "dPACE": ["abi", "evm.bytecode.object"] //carSharing needs to be the same name as the contract!!
          }
       }
       }
    })
 ); 

fs.ensureDirSync(buildPath);

for (let contract in output){
    fs.outputJsonSync(
        path.resolve(buildPath, contract + '.json'),
        output[contract]
    );
}