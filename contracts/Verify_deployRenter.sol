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
// def checkHash(field[3] inputs, field[2] expectedHash) -> (field):
// 	field[2] hash = [0, inputs[0]]
// 	for field i in 1..3 do
// 		field[4] toHash = [hash[0], hash[1], 0, inputs[i]]
// 		hash = sha256packed(toHash)
// 	endfor
//
// 	hash[0] == expectedHash[0]
// 	hash[1] == expectedHash[1]
// 	return 1
//
//
// // genHelper0: _balance
// // genParam0: reveal(_balance, me)
// // genParam0PK: reveal(_balance, me)
// def main(private field genHelper0, private field genParam0, private field genParam0R, private field genParam0PK, field inputHash0, field inputHash1) -> (field):
// 	1 == checkHash([genHelper0, genParam0, genParam0PK], [inputHash0, inputHash1])
// 	field genParam0Dec = genHelper0
// 	genParam0 == enc(genParam0Dec, genParam0R, genParam0PK)
// 	return 1
pragma solidity ^0.5.0;
import "./verify_libs.sol";

contract Verify_deployRenter {
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
                uint256(0x2ae45f8e98330a3987364c8f3c4febcf4071caf321258210ae202dacf17a0873),
                uint256(0x219bd99fbcd16aa611f8f4a3d0bbdcf8bbf1990a54d3827919af31e2e3fb95b4)
            ],
            [
                uint256(0x1b72c8da05ae70a3cc9572ec67bd0e7bf500dcdc91e450e78850f7594cfac5f8),
                uint256(0x173ee9f2622d94af2a7ce7207ec460ded57d3096d26cf16d8b8740e401688d08)
            ]
        );
        vk.Galpha = Pairing.G1Point(
            uint256(0x1c783b70bba4e73ffe4fc8432635ecdc497468d9134f2da49fc15e5cba6cfd82),
            uint256(0x290e8c282b58f2d827ad1d3da304ea51d61cb3b92fb6152be8492a8b2208d427)
        );
        vk.Hbeta = Pairing.G2Point(
            [
                uint256(0x05e44ad5d62e7f6356be1de07baa2ff41d5ce0077f652280777d2954a04d37f3),
                uint256(0x21b32b33d03e8a5e7a1d5a05d49100ca270aebae34e7ea193dd3bbbf1e38472d)
            ],
            [
                uint256(0x08d776a2e085ff1e17da6c3019b9bd6ba01f1008b3382b14b9740aff03ebbc08),
                uint256(0x22e5ceafb872f4dc4e9465fce25508c601a683667e4142d5c2e5dfd9d32b7d5b)
            ]
        );
        vk.Ggamma = Pairing.G1Point(
            uint256(0x29f6ad79a0c87b9ede79c6d72630d5db98c63965582d56caeb212cd960e7cefc),
            uint256(0x1e80cc870e53cebeaf59a404f7b15eaadce45a160eee626c07e9ccbc2e7e0055)
        );
        vk.Hgamma = Pairing.G2Point(
            [
                uint256(0x25328c33a84466c3900eedba2981190593e108d23c798c463a4fae0dfdb9e143),
                uint256(0x0826a3baad59161100e5b3fd68cd2e67a1dc0034b512b812ab3967c65e6c8fe0)
            ],
            [
                uint256(0x24bfe10fa659a92141c6800eec72fd61707a6a4464bc76cc9622bec16e8a0898),
                uint256(0x12352d3f3fbf1d306f26dd6cc06765d0289d881f722d803f6de6576bce93fefd)
            ]
        );
        vk.query = new Pairing.G1Point[](4);
        vk.query[0] = Pairing.G1Point(
            uint256(0x14b9a25a5a1b47cb13f3def118f12cddda51ff548214070ec84d38969db232b8),
            uint256(0x2510fe9adb6bf919f7f8ba26510fd506777fd8c83667f9bf4ae2866e68ff804c)
        );
        vk.query[1] = Pairing.G1Point(
            uint256(0x228bf5d02f76720ebd1195e76a939b824bc2460c4a69e389ef02769d1e4840f1),
            uint256(0x0cf917674388c82fdfcccdead05257d8a3cd3c4c8a6bc1df72cbf49fc6034701)
        );
        vk.query[2] = Pairing.G1Point(
            uint256(0x0b3497a74ee887bda63473374f0f311f6904b928e70a4fe269b8a1474a903493),
            uint256(0x2abbaa7ab8551d798b312a01d1f538e66fe55f8d5c3de3901174ac33e92c29fd)
        );
        vk.query[3] = Pairing.G1Point(
            uint256(0x1b8c1ea6c0a9630e03e16b41b17f8fdbda0e3c16e0749c3a9b6a9ad06603a699),
            uint256(0x13c38505998e37b6dcc36770048530e7bd48e65c7e6493db7c44e40bb11addf0)
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
            emit Verified("Transaction successfully verified.");
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
