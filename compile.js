/* If we would require(MassCarSharing.sol), the node engine would attempt to
execute it as if it is a javascript file, so we use 'path' & 'fs'
to read in the contents of the file differently
These are standard modules so no need to npm install them */
const path = require('path');
const fs = require('fs');
const solc = require('solc');

// the path to MassCarSharing.sol, __dirname is a constant defined by node and
// will always return the valid current working directory
const massCarSharingPath = path.resolve(__dirname, 'contracts', 'Signature.sol');
// This reads the contents of the file using the filesystem (fs) module
const source = fs.readFileSync(massCarSharingPath, 'UTF-8');

// The actual compile statement, changed according to most recent section "using the compiler" in Solidity documentation
// module.exports makes the compiled files available to others
const compiledContract = solc.compile(JSON.stringify({
   language: "Solidity",
   sources: {
      ":massCarSharing": {
         content: source
      }
   },settings: {
      outputSelection: {
         "*": {
            "Signature": ["abi", "evm.bytecode.object"] //carSharing needs to be the same name as the contract!!
         }
      }
      }
   })
); 

module.exports = JSON.parse(compiledContract).contracts[':massCarSharing'].Signature;