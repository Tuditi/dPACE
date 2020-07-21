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
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.H = Pairing.G2Point([uint256(0x2e51203e409b94cc7ebd7fda4ce14e45c17ced556c13e05fa78e0fc61e812b3c), uint256(0x03cff617ee54c610c22d4292b91eb349805a3c2c6543d5ad004962f863665c3b)], [uint256(0x197b9f928444f4b5d726baa5b6b813300576af237cb857bab6e430a0eda26c6e), uint256(0x20fb15cf29beea0423c8eece253f86ec2b3afb1e138bb20cf8b69584aa1e1178)]);
        vk.Galpha = Pairing.G1Point(uint256(0x2cf22dca536e89b28b095d528df2cc0886b15bb849c99f8b6fcb3f141ddf0d94), uint256(0x04667519130e5247ccf2bc5b4e1b8f728c88e17102b8f968bd5ede2e6b6ccd37));
        vk.Hbeta = Pairing.G2Point([uint256(0x286dadf18ad236cd2afd7308466bf662f43cdaff1ab3a5a0d22edee77c520deb), uint256(0x121b0dbcc4345b59d4476d70f0a39f99da83559d43d64683bc3e0fd0d58a0997)], [uint256(0x111a935a9b47a7c7274258e5de31fe7b476181e2c1d40914e6701c64dc04a807), uint256(0x1e80b62e70e46a69c918ea2a986102328be0ab2d65fc627c59781ef735d0409a)]);
        vk.Ggamma = Pairing.G1Point(uint256(0x120b62be5e1ef8cbf21906afa0ddfa6c5f67711a19525e0cfe4a05cd787a5190), uint256(0x1a49db6c298216663d9383c48531df73e60a0c77b933d6075fad4d524de6f27d));
        vk.Hgamma = Pairing.G2Point([uint256(0x1e9b8bd13d878c31feaa8f05c2a0873ecca268e2bae74a6f61fc3b7762ac4bdf), uint256(0x02e90bf8fdef2090207e38edff94b5c89849d412739557ae9310173b9324b89f)], [uint256(0x15285f66d94c8e1e24a8dfd0985ab6b7bd1d8bffc718f913250e5fc39df9c976), uint256(0x18c155a189f958577a49239679dbc625cd7d657cab848c720cdcc6eaddfe025f)]);
        vk.query = new Pairing.G1Point[](4);
        vk.query[0] = Pairing.G1Point(uint256(0x2c4c4ffa8720ea15e3258203a19e2e568b2b3f8a7069311b01fa9c92feec70ad), uint256(0x0fd4ebdbdc2d7b82c7756b8142ddb782ed8de14567db353a9fe0e976fa2de6e1));
        vk.query[1] = Pairing.G1Point(uint256(0x15ecfb609eb6813cf720ca6de2a1813a077db687cf395a8cd681099f1eb94563), uint256(0x20bbc27201d9fd8fc0278a284801fa3cce9176867ebe2898ef2cbefb05b9638e));
        vk.query[2] = Pairing.G1Point(uint256(0x0fd3ce10d5d09e44e702f47954dec0eaffbcaacf3a722fd2a08e3d708d16b8da), uint256(0x270843182d9dc7f141820d8d522fcd8f9906229661f3fb94f3081bd0870aa793));
        vk.query[3] = Pairing.G1Point(uint256(0x14795592e053017b3122a159ee348c167133134b685f3de57f22e36e04054004), uint256(0x0a17abb75153a797cad96df0263800b7e61662e1d42249a06c69d82e5922cc05));
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
