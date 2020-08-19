# Thesis
Master's Thesis on the design of a privacy-preserving car sharing protocol implemented on the Ethereum blockchain for the department Electrical Engineering of the KU Leuven.

Steps to reproduce:

Step 1)

Deploy all smart contracts to the blockchain:

- PKI: Contains the Public Key Infrastructure necessary to support zk-proofs and ring signatures. (gas = 324,046)
- Signature: Contains the functions to generate and verify ring signatures. (gas = 1,578,566)
- Verify_deployRenter: Contains the verification circuit of the zk-proof that is used to deploy a renter. Checks whether encrypted value of the inital balance >= Deposit. (gas = 1,306,091)
- Verify_renterBooking: Contains the verification circuit for the zk-proof used to book a car by the renter. Checks whether encrypted balance >= necessary deposit. (gas = 1,306,079)
- Verify_renterPayment: Contains the verification circuit for the zk-proof that is supplied when the renter pays the fee. Checks whether the encrypted new balance equals the encrypted current balance minus the encrypted fee. (gas = 1,305,647)
- dPACE: handles the functions related to booking and payment of a smart contract. This is the interface with which the actors (Car Owner, Car Renter and Car interact with). Upon deployment the constructor expects the addresses of the previously defined smart contracts. (gas = 4,731,498)

Together with the deployment of the Verify smart contracts, the library that performs elliptic curve operations (BN256G2) and pairings (Pairing) is deployed. The linking of the verification smart contracts and the libraries happen automatically. (gas = 1271585 + 912773)

Step 2)

Announce Public Keys for zkay in the PKI-contract-> This uses dummy encryption enc(msg,pk) = msg+pk
(gas = 62,535)

Step 3) Generate alt_bn 128 keys in Sage

Script: 
F = FiniteField(0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
C = EllipticCurve(F,[0,3]) //Definition of the curve: y²=x³+3
G = C.point((1,2))
PrivateKey = randombits(256)
PublicKey = PrivateKey*G

Step 4) Announce compressed public keys (e.g. 5) of car and renter in PKI. These can be used by anyone as mix-in keys. The renter can use the private key corresponding to their public key once to mitigate replay attacks. (An adversary could impersonate someone by using previously published key material.)

Step 5)

Deploy Car (by car owner) (gas = 86,560)
Validate Car (by car) (gas = 49,149)
Deploy Renter (by car renter) with a zk-proof for 1 ether (gas = 541,610):
["0x134561ab48445aeabec225028b7cd87a8e5a354498f509b031f329a771041912","0x031429a0dbee4f13488dee528c6433769fc9ce553dc61bd6f4d1207e1d16bb79","0x02e1771807d91e429237288c4ee82d612db124aa7d8bccd5ece3abff3d7c0137","0x2db59bb4c35d41388b3b9a1823cfe1c6b18fa0b1877760724464fb4fce9a374f","0x18f3613e60bc6dde487e413dfd9d47516851771bf8494167ae24c2220b03a648","0x1a8d00480bbdea4323f92c25c8b8be56d1309237e3798fd11d996c479bbf8ed6","0x0071ff2d1c53284f289bd529b95ea480283ec8435b0efc671ed5773d7e95fc3b","0x168196550842267ac3fb6cbbd76da6a759f6b9d46e7e31b6b77c77e570889d46"]



Step 6) Generate Hashlock for the renter and ring signature

Step 7) Generate Hashlock for the car and ring signature

Step 8) Renter Booking

Step 9) Car Booking

Step 10) Car Payment

Step 11) Renter Payment