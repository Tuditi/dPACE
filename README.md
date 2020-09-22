# Thesis
Master's Thesis on the design of a privacy-preserving car sharing protocol implemented on the Ethereum blockchain for the department Electrical Engineering of the KU Leuven.

Smart Contract Address on the Rinkeby testnet: 0x85f8e621548c9c2114Edca97FBd4D9B64Eb6820c

Prerequisites:
- zkay v. 0.1 (https://github.com/eth-sri/zkay/tree/ccs2019).
This module is used to generate zk-proofs by following the instructions provided on their github repository. This boils down to configuring the scenario.py file according to the specific needs of the program and running the scenario generator of zkay.

Steps to reproduce with additional data in data.txt:

Step 1)

Deploy all smart contracts on the blockchain:

- PKI: Contains the Public Key Infrastructure necessary to support zk-proofs and ring signatures. (gas = 324 046)
- Signature: Contains the functions to generate and verify ring signatures. (gas = 1 578 566)
- Verify_deployRenter: Contains the verification circuit of the zk-proof that is used to deploy a renter. It checks whether the encrypted value of the inital balance >= Deposit. (gas = 1 306 091)
- Verify_renterBooking: Contains the verification circuit for the zk-proof used to book a car by the renter. It checks whether the encrypted balance >= necessary deposit. (gas = 1 306 079)
- Verify_renterPayment: Contains the verification circuit for the zk-proof that is supplied when the renter pays the fee. It checks whether the encrypted new balance equals the encrypted current balance minus the encrypted fee. (gas = 1 305 647)
- dPACE: handles the functions related to booking and payment of a smart contract. This is the interface with which the actors (Car Owner,Car Renter and Car interact with). Upon deployment the constructor expects the addresses of the previously defined smart contracts. (gas = 4 731 498)

Together with the deployment of the Verify smart contracts, the library that performs elliptic curve operations (BN256G2) and pairings (Pairing) is deployed. The linking of the verification smart contracts and the libraries happen automatically in Remix. (gas = 1 271 585 + 912 773)

Step 2)

Announce public key of the renter in the PKI-contract -> This used for the zero-knowledge proofs and the encryption of the balance of the renter. Warning: this is done through dummy encryption enc(msg,pk) = msg+pk!

Step 3) Generate alt_bn 128 keys in Sage, which are used to generate ring signatures

Script: 

F = FiniteField(0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
C = EllipticCurve(F,[0,3])
G = C.point((1,2))
PrivateKey = getrandbits(256)
PublicKey = PrivateKey*G

Step 4) Announce compressed public keys of car and renter in PKI. These can be used by anyone as mix-in keys. The renter can use the private key corresponding to their public key once to mitigate replay attacks. (An adversary could otherwise impersonate someone by using previously published key material.)

Step 5)

Deploy Car (by car owner) (gas = 86 560)\n
Validate Car (by car) (gas = 49 149)\n
Deploy Renter (by car renter) with a zk-proof that the encrypted value of the balance equals the sent deposit. (gas = 541 610):

Step 6) Generate Hashlock for the renter and ring signature and zk-proof that balance >= 1

Step 7) Generate Hashlock for the car and ring signature


Step 8) Renter Booking

(gas = 1 058 655)

Step 9) Car Booking

(gas =  673 825)

step 10) Renter signs timestamp 

Timestamp is measured in unix time and used for calculating the fee of the rental.
-> This value is sent back to the car and is used in step 11.

Step 11) Car Payment

Submit the timestamp, the ring signature of the renter and the necessary information for a new booking (location, token, etc.)

(gas = 610 567)

Step 12)  Car signs encrypted fee

Step 13) Renter Payment

(gas = 1 038 611)

