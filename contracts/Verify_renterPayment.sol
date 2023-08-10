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
import './verify_libs.sol';

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

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.H = Pairing.G2Point(
            [
                uint256(0x182e636cdd3435c001c26c4d06c302696ce32c6d73ffca2b40fb746ba539b9ee),
                uint256(0x295e33ca88c25a3af75a144849cea9a39c471cdedd9a9dec18a71265288f7572)
            ],
            [
                uint256(0x266a641ce676dfe3a4890eda24833dac7bd6b10a2f4be8004debcb9575092f1e),
                uint256(0x0d64f39b96fdd2e44bc1fc1659aa2293321ade7383873b98b1f718ae0e98cf75)
            ]
        );
        vk.Galpha = Pairing.G1Point(
            uint256(0x0ae8fa82e5b140621e3cd68e268ee4cb562bc460c2730984f0617db8a360abf0),
            uint256(0x0994d68cf10bb7216a0af1008817b109d035fa06c107ce65f485b46e79df1ca7)
        );
        vk.Hbeta = Pairing.G2Point(
            [
                uint256(0x1ab6a1dd71079f1839d77db52b22c46bf7a09e6792f94b96d7ce527b6345420c),
                uint256(0x1ae14d894ed3f078c3944f6ede451f2512a3d4e60179a76a0ac65aea0cf98cdd)
            ],
            [
                uint256(0x3052103362ed1e330c7fdb9626d36b9f5b855c52a3fdee583083f598e5488d14),
                uint256(0x13d3af88d41949df9ce5a8875a01c87c23b0ffae2e207bfd2fbe5da06e601328)
            ]
        );
        vk.Ggamma = Pairing.G1Point(
            uint256(0x296afcb2ab086c4b47f93403a81a34ad3a6710672f9664d725dba58cded17f64),
            uint256(0x2c9dd85bc532180adf6d82b2f89faaa118651d9a2d8d35e47fc39945610eb6fe)
        );
        vk.Hgamma = Pairing.G2Point(
            [
                uint256(0x02bf0e17c20fd7ebc5669e3889e586ca7f5dd29c744735cd6282e6c92a3d3bc6),
                uint256(0x10ab7dfb689a3b44b58cac3693e2a1ea395ecaf2d195cbbf6440927aa0242ba9)
            ],
            [
                uint256(0x125bb63fc28edff0f1e4b9a0569b3a5dd095d016356e00f137f65cb524a2dbb8),
                uint256(0x19f617c651f76b97d53ea39cf61b503e84270c7a15c47122cf39824b597d6da6)
            ]
        );
        vk.query = new Pairing.G1Point[](4);
        vk.query[0] = Pairing.G1Point(
            uint256(0x16ff281f5ed107de09354d4c84213c87356f7d7f7ddc111e5a8e23149cf1f52d),
            uint256(0x10c24e0e839c6310a9858a39c2fa2c7e0e3cd538fd2725d8b5a8b55fe63a1019)
        );
        vk.query[1] = Pairing.G1Point(
            uint256(0x1d0f608a1559eb913cf76c4e2448bc2f35df265afe5139689e6e1b8ce5822e9b),
            uint256(0x02f246b36d6de73c44c06cd0fb1f2cd9cbc2833e2f5c0ffe3ca4e74cb4ba3eaf)
        );
        vk.query[2] = Pairing.G1Point(
            uint256(0x035a58e5012847842d4ea8728bb4255df29c5f3ab10bdf227cb6475f08937f8f),
            uint256(0x25002dfddf69131331a8c7e54fc3837134c6f4218d77ddafdff94b62d5c04d63)
        );
        vk.query[3] = Pairing.G1Point(
            uint256(0x1f222c5ae277f098ad3b6842c6a43d8925170f6ce9e273abf7fb2ab7585c64d2),
            uint256(0x12b047cda0acd2604920c3c2109adccad1db6e34a08e166af2386fdeff4709a7)
        );
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
        if (
            !Pairing.pairingProd4(
                vk.Galpha,
                vk.Hbeta,
                vk_x,
                vk.Hgamma,
                proof.C,
                vk.H,
                Pairing.negate(Pairing.addition(proof.A, vk.Galpha)),
                Pairing.addition(proof.B, vk.Hbeta)
            )
        ) return 1;
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
        for (uint i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            emit Verified('Transaction successfully verified.');
            return true;
        } else {
            return false;
        }
    }

    function check_verify(uint[8] memory proof, uint[3] memory input) public {
        require(
            verifyTx(
                [proof[0], proof[1]],
                [[proof[2], proof[3]], [proof[4], proof[5]]],
                [proof[6], proof[7]],
                input
            )
        );
    }
}
