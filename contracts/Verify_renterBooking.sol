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
import "./verify_libs.sol";


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
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.H = Pairing.G2Point([uint256(0x2c2db977b6e9705f71dc3f8677ea878d2e29de6e8b24f454c6fdc8f3dbb1f764), uint256(0x18579d007236025d4cbe0618cdb90e1c10190cb2de9144e69fbcb2709e3a5406)], [uint256(0x1a5216fcd48b8fc8f8381746bdd715d4b570faf0fbf260c8a6f0d159244c1af6), uint256(0x0fc0316ab0dc7ad934deb19c39842507655ea9f73e8d17b5f9dd461a5f888a1f)]);
        vk.Galpha = Pairing.G1Point(uint256(0x1683b370bb77427cdc0bd1404a3087e89494537b3bc1b3fb4e47d0a2b90a5a61), uint256(0x1517b3aeb0a8bb37f66f94cf8da4175705de1fd4e665458a8c764f835649b01f));
        vk.Hbeta = Pairing.G2Point([uint256(0x2f37dc55c02249b562e0c0bae8cd10ee0b8cd54f2119db1e1abaed49a8f61478), uint256(0x12c30c47ad0f5bfd34a5bc22e35cf464dff642cf9020cc4bb7e6910d8aaf9b13)], [uint256(0x2e923fe6c92ac7ca55c98ef5c07354536bbafbec4a62b74fe5b0e011c9ce3d82), uint256(0x03c78f563002a8f592a9e16ea51abfee71d837b38ad73b60118926f88d260f98)]);
        vk.Ggamma = Pairing.G1Point(uint256(0x04572e27d54ca81ec33f0da527276405ab2c828347aefdc0a2eb9123b121ceb9), uint256(0x2bf68e472d716582c5bc2705e1a19b949ae295639ff69b160e9000aadf952f7d));
        vk.Hgamma = Pairing.G2Point([uint256(0x1753d73b561070ae5608a83c4e2ff63517ffa83cd9493bee27bc2d0373b6ba7b), uint256(0x1afbdea22e4429ef00f742b56f403be96e3269f44dcdcc5b9518b0cbb33b782b)], [uint256(0x2416808c68783a514f19eb2bbef3f2776bbed09ac6d1ed815d79dd36ed708c94), uint256(0x2f033c06493c7257f9760d1bda47f38005ddbcf1df1a33f348ce528e8d2afd40)]);
        vk.query = new Pairing.G1Point[](4);
        vk.query[0] = Pairing.G1Point(uint256(0x20538e9a79fe5c69f5fc3ffe7340dd7edf2c0ac60ee5749ad67ecc1039bc59c1), uint256(0x1b5efbb00e2a483705a453e902c3805af5431b4f1536e228a2d4ccee220d6149));
        vk.query[1] = Pairing.G1Point(uint256(0x23b41b9cafb207865065a744e8355d6dc036a802184c983e8c2e52dc336d7aa8), uint256(0x066a015b5b510cbab9c4641919acc1cb39351f6d4ae7ac0155cd60a8ff343156));
        vk.query[2] = Pairing.G1Point(uint256(0x1d31703f82173fdbfe27588bc2a9f5d4d7f771d4caee350f09ba839614dd82a7), uint256(0x2e595e90e9e2e23c6cc0dc4b4eab01ccee2098403342e49ad0d6d088d3d8d8d3));
        vk.query[3] = Pairing.G1Point(uint256(0x12bfaae99a57899aad0c7c9e61bde23ddccdcabfce94bf9afb2e88f4e5d5c64e), uint256(0x1e82da659c46f4b225bfe36737425a6ef90ec4a1ad1e47f162d91527f854a3b2));
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
