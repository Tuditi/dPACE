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
// // genHelper0: renter_blindedBalance[me]
// // genHelper1: DEPOSIT
// // genParam0: reveal(renter_blindedBalance[me] >= reveal(DEPOSIT, me), all)
// def main(private field genHelper0, private field genHelper0SK, private field genHelper1, private field genParam0, field inputHash0, field inputHash1) -> (field):
// 	1 == checkHash([genHelper0, genHelper1, genParam0], [inputHash0, inputHash1])
// 	genParam0 == if dec(genHelper0, genHelper0SK) >= genHelper1 then 1 else 0 fi
// 	return 1
pragma solidity ^0.5.0;
import './verify_libs.sol';

contract Verify_renterBooking {
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
                uint256(0x2a6431f4a430da99d14e975532c7d782c9b9e2122393f6e1b775f5f4c95c21c6),
                uint256(0x185711548284a7d9f0d031863d14673a54034f6b9fb742cfe176a9b74fffe834)
            ],
            [
                uint256(0x0f53860d74577799ba5e73ebe716f4bc9b0e4a7dcbdcea14372d01ed300e2972),
                uint256(0x0bc165cccb912edb7ac5e4e7f2e82a23cfa9dc76136be8353c0e056715b4ba15)
            ]
        );
        vk.Galpha = Pairing.G1Point(
            uint256(0x20e70fe2b3b3442ec6f0dae0d104854e030e86bd474c63cc3dd60084612bcade),
            uint256(0x141f4bd0f4acd7b7fa03ee676f01f7e5a96a113aeb35a57db0ee7e15e1cbdb5d)
        );
        vk.Hbeta = Pairing.G2Point(
            [
                uint256(0x091b078fe98930c5997869d8472f3edd8d8aa5d589a0d2f916e38b5a5aba0ad8),
                uint256(0x304ba95b8e2cb53a248b14e0100507294b77f9a5a03d805e4aec91ac5a487ed9)
            ],
            [
                uint256(0x0afe6edff5bba4cf216a9b4254ee385c5225e047769e507f6bfe53b864a6e445),
                uint256(0x26b82494d7dfa940d2e5b7279980a8ad490c6420370f3deff21c1bc940eabcbc)
            ]
        );
        vk.Ggamma = Pairing.G1Point(
            uint256(0x0a5e23641062ae7d2075951dd0651e032573ba0e09ff9ecb293e170e8778fa54),
            uint256(0x205da84a73862f9271ec35b29fee5f6a57358db3a88806e366ced8f086892e39)
        );
        vk.Hgamma = Pairing.G2Point(
            [
                uint256(0x0239950ca9e25a154b8f4a9178efcafe17eb867c8e4602989791beea488638eb),
                uint256(0x178da1cc011e17cc89404565083ea033bc38b0da97e2851ff392cea80f90e59a)
            ],
            [
                uint256(0x0b7b694b36c0ec789f9d5f6a6fa55379ef749d4e756c32f34024a275d030f2d5),
                uint256(0x14aed2b34e473b85f16ba7e90d2b5d5a209f66c4116bc0aa5cebe69c6194b92e)
            ]
        );
        vk.query = new Pairing.G1Point[](4);
        vk.query[0] = Pairing.G1Point(
            uint256(0x2debd9566767a972da7d08b23abf0ded24544286e89d6db7bbd2ce42d7304ceb),
            uint256(0x1a29c0d78d9c04d6c469eb1bc2c156b9da70c8e0f613a323945210334a46da54)
        );
        vk.query[1] = Pairing.G1Point(
            uint256(0x0aa427fd825bb5458f2a0b6dbc7ad5145567c0d1a22ee36d54d3b0e4267600e5),
            uint256(0x0da1cf7540739a741e032eeb36f00abc6fca95042dd9b631ef99f125ace00d97)
        );
        vk.query[2] = Pairing.G1Point(
            uint256(0x15a05b0d22513a708b0458147d17e3b9184200b384a83a1f9034ed029acc76e7),
            uint256(0x069666d488642a502214aaaa92f426177d5b6294fe86de4aa24ee31fbc70b3a8)
        );
        vk.query[3] = Pairing.G1Point(
            uint256(0x2d669e872707e2661c33cfa74fcf5394ea2555b76d08aa8a6bfd1925df36b4f9),
            uint256(0x0ac2af5320197aade98d79bb5b51c68736d844bf0cebc727294666f12537333a)
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
