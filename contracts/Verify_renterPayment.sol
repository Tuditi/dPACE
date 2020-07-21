// 
// def dec(field msg, field key) -> (field):
// 	return msg - key
// 
// def enc(field msg, field R, field key) -> (field):
// 	// artificial constraints ensuring every variable is used
// 	field impossible = if R == 0 && R == 1 then 1 else 0 fi
// 	impossible == 0
// 	return msg + key
// 
// import "hashes/sha256/512bitPacked.code" as sha256packed
// 
// def checkHash(field[6] inputs, field[2] expectedHash) -> (field):
// 	field[2] hash = [0, inputs[0]]
// 	for field i in 1..6 do
// 		field[4] toHash = [hash[0], hash[1], 0, inputs[i]]
// 		hash = sha256packed(toHash)
// 	endfor
// 	
// 	hash[0] == expectedHash[0]
// 	hash[1] == expectedHash[1]
// 	return 1
// 
// 
// // genHelper0: uint@me _fee
// // genHelper0PK: uint@me _fee
// // genHelper1: renter_blindedBalance[me]
// // genHelper2: _fee
// // genParam0: renter_blindedBalance[me] - _fee
// // genParam0PK: renter_blindedBalance[me] - _fee
// def main(private field genHelper0, private field genHelper0Value, private field genHelper0R, private field genHelper0PK, private field genHelper1, private field genHelper1SK, private field genHelper2, private field genHelper2SK, private field genParam0, private field genParam0R, private field genParam0PK, field inputHash0, field inputHash1) -> (field):
// 	1 == checkHash([genHelper0, genHelper0PK, genHelper1, genHelper2, genParam0, genParam0PK], [inputHash0, inputHash1])
// 	genHelper0 == enc(genHelper0Value, genHelper0R, genHelper0PK)
// 	field genParam0Dec = dec(genHelper1, genHelper1SK) - dec(genHelper2, genHelper2SK)
// 	genParam0 == enc(genParam0Dec, genParam0R, genParam0PK)
// 	return 1
pragma solidity ^0.5.0;
import "./verify_libs.sol";


contract Verify_renterPayment {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point H;
        Pairing.G1Point Galpha;
        Pairing.G2Point Hbeta;
        Pairing.G1Point Ggamma;
        Pairing.G2Point Hgamma;
        Pairing.G1Point[] query;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.H = Pairing.G2Point([uint256(0x1555507785a1b28e04f5508e0d8d9f2f4540c5534ed6068a23bfd1d301a2b586), uint256(0x0d4e65c2bd737120df18e441ef6155b7dc7faed4885da62ee9e2a66e7036f901)], [uint256(0x06107574db27aa0b2e667bc3a4911dccecee8237880ea48364903e65263be394), uint256(0x039ed8c0347025a9a95077f6725d10884a2c96e59e1d6790764e2eee561be9ca)]);
        vk.Galpha = Pairing.G1Point(uint256(0x0084a2888e8d5c23c2b03fbb661af4ec2315be8e23a825a83cb7900088641cb7), uint256(0x1801df742e4dc0e5dcbae3f52b78b28ae450c799c6613a369b70035f0dcecb55));
        vk.Hbeta = Pairing.G2Point([uint256(0x0b7df37735023d30966dac03864fa5e28e8c0f39033ae8dc489a7fc052acf543), uint256(0x26832108343f2f44996fdbaeb417d7d41085426d338bc514d257213b941f755b)], [uint256(0x0f445438429cbd72588c093c6ac13cdc0ef96a124ecf95dc0b4b8123d4993802), uint256(0x13f44edc5b7183ee0c5a132cf231d813da355e1e2beaf75d86787b64ccdcfd8c)]);
        vk.Ggamma = Pairing.G1Point(uint256(0x2b09855297edd94b50ee2d57477d8a7e44ef9670d593d7e91fcf3b09341d04c1), uint256(0x2b47e4158e54064f66504cef581191f31f104c3f39369f29bb5a5ab2e83d3874));
        vk.Hgamma = Pairing.G2Point([uint256(0x23827624a08c62cecdc18b1d83921d62f5df20715a2f7e41d26f0ef900ff0916), uint256(0x188613f5cf7923ab5cb0f56dac90f1fc15c8155fb09dbe637add97f08f252bd8)], [uint256(0x2f52045fb2d2209899ff0036b02297a9255aa6d04d29289f91982d044170188c), uint256(0x231025ef882f647eaf736e04aee1e901600318447a32f7ea5f08b798f14bb79e)]);
        vk.query = new Pairing.G1Point[](4);
        vk.query[0] = Pairing.G1Point(uint256(0x22f25f617c5e8e6305b7c47eabf65d9a7189bd726b0f2bdc064aed54e86c23ce), uint256(0x00c7a0fd4c260c4c2362775fe7663e7cc584137f9686cfe3515e2c445e0eb2f0));
        vk.query[1] = Pairing.G1Point(uint256(0x18fa1db0a5eb621e129e81a9cba7612d03c62e6555f6ebb8fa409640f038989a), uint256(0x25fd8c10aca09cc206d12e989e77dbc02c36a3b929d155aa41c0c147fcefece9));
        vk.query[2] = Pairing.G1Point(uint256(0x20cc06408ff17887c594f65508daaf34319541ba3e9d5cbe50369bc0f5587695), uint256(0x0aad332ca4c8a80692da2a8bfb9ca8d59c4260a90ef58c9a7a407844ad77f517));
        vk.query[3] = Pairing.G1Point(uint256(0x0b27e59509862306391708dfaf78898a79778043b195403c0ec6906063bd768c), uint256(0x21225467a6e6fb652bcf3d02939d6f8607623192e76158ce67dd976050858b5d));
    }
    function verify(uint[] memory input, Proof memory proof) internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.query.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.query[i + 1], input[i]));
        vk_x = Pairing.addition(vk_x, vk.query[0]);
        /**
         * e(A*G^{alpha}, B*H^{beta}) = e(G^{alpha}, H^{beta}) * e(G^{psi}, H^{gamma})
         *                              * e(C, H)
         * where psi = \sum_{i=0}^l input_i pvk.query[i]
         */
        if (!Pairing.pairingProd4(vk.Galpha, vk.Hbeta, vk_x, vk.Hgamma, proof.C, vk.H, Pairing.negate(Pairing.addition(proof.A, vk.Galpha)), Pairing.addition(proof.B, vk.Hbeta))) return 1;
        /**
         * e(A, H^{gamma}) = e(G^{gamma}, B)
         */
        if (!Pairing.pairingProd2(proof.A, vk.Hgamma, Pairing.negate(vk.Ggamma), proof.B)) return 2;
        return 0;
    }
    event Verified(string s);
    function verifyTx(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[3] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            emit Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
	function check_verify(uint[8] memory proof, uint[3] memory input) public{
		require(verifyTx(
		[proof[0], proof[1]],
		[[proof[2], proof[3]], [proof[4], proof[5]]],
		[proof[6], proof[7]],
		input));
	}

}
