pragma solidity ^0.5;

//Useful link: https://www.johannes-bauer.com/compsci/ecc/#anchor12
contract Signature {
    //alt_bn128 constants
    uint256[2] public G1 = [1, 2];
    uint256 public constant N = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    uint256 public constant P = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    //Used for Point Compression/Decompression
    uint256 public constant ECSignMask =
        0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 public constant a = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52; // (p+1)/4

    //Debug variables
    uint256[32] ring_signature;
    uint256[2] hash_point;
    uint256 hash_function;
    uint256 evaluate_y;
    bool x_on_curve;

    //=== RingVerifyN ===
    //Inputs:
    //  destination (address[]) - list of payable ETH addresses
    //  value (uint256[]) - list of values corrosponding to the destination
    //  signature (uint256[2*N+2]) - ring signature
    //      signature[0] - keyimage for private key (compressed)
    //      signature[1] - c0 - start of ring signature - scaler for PublicKey[0]
    //      signature[2     ... 2+(N-1)] - s0...s[N-1], scalar for G1
    //      signature[2+N   ... 2*N+1  ] - Public Keys (compressed) - total of N Public Keys
    //      signature[2*N+2 ... 31     ] - Padding (0)
    //      e.g. N=3; signature = { Ik, c0, s0, s1, s2, PubKey0, PubKey1, PubKey2 }
    //Outputs:
    //  success (bool) - true/false indicating if signature is valid on message

    //Base EC Functions
    function ecAdd(
        uint256[2] memory p0,
        uint256[2] memory p1
    ) public returns (uint256[2] memory p2) {
        assembly {
            //Get Free Memory Pointer
            let p := mload(0x40)

            //Store Data for ECAdd Call
            mstore(p, mload(p0))
            mstore(add(p, 0x20), mload(add(p0, 0x20)))
            mstore(add(p, 0x40), mload(p1))
            mstore(add(p, 0x60), mload(add(p1, 0x20)))

            //Call ECAdd: call contract at address a with input mem[in..(in+insize)) providing g gas and v wei and output area mem[out..(out+outsize))
            //returning 0 on error (eg. out of gas) and 1 on success
            let success := call(sub(gas(), 2000), 0x06, 0, p, 0x80, p, 0x40)

            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                revert(p, 0x80)
            }

            //Store Return Data
            mstore(p2, mload(p))
            mstore(add(p2, 0x20), mload(add(p, 0x20)))
        }
    }

    function ecMul(uint256[2] memory p0, uint256 s) public returns (uint256[2] memory p1) {
        assembly {
            //Get Free Memory Pointer
            let p := mload(0x40)

            //Store Data for ECMul Call
            mstore(p, mload(p0))
            mstore(add(p, 0x20), mload(add(p0, 0x20)))
            mstore(add(p, 0x40), s)

            //Call ECAdd
            let success := call(sub(gas(), 2000), 0x07, 0, p, 0x60, p, 0x40)

            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }

            //Store Return Data
            mstore(p1, mload(p))
            mstore(add(p1, 0x20), mload(add(p, 0x20)))
        }
    }

    function CompressPoint(uint256[2] memory Pin) public returns (uint256 Pout) {
        //Store x value
        Pout = Pin[0];

        //Determine Sign
        if ((Pin[1] & 0x1) == 0x1) {
            Pout |= ECSignMask;
        }
    }

    function EvaluateCurve(uint256 x) public returns (uint256 y, bool onCurve) {
        uint256 y_squared = mulmod(x, x, P);
        y_squared = mulmod(y_squared, x, P);
        y_squared = addmod(y_squared, 3, P);

        uint256 p_local = P;
        uint256 a_local = a;

        assembly {
            //Get Free Memory Pointer
            let p := mload(0x40)

            //Store Data for Big Int Mod Exp Call
            mstore(p, 0x20) //Length of Base
            mstore(add(p, 0x20), 0x20) //Length of Exponent
            mstore(add(p, 0x40), 0x20) //Length of Modulus
            mstore(add(p, 0x60), y_squared) //Base
            mstore(add(p, 0x80), a_local) //Exponent
            mstore(add(p, 0xA0), p_local) //Modulus
            //Call Big Int Mod Exp
            let success := call(sub(gas(), 2000), 0x05, 0, p, 0xC0, p, 0x20)

            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                revert(p, 0xC0)
            }

            //Store Return Data
            y := mload(p)
        }
        //Check Answer
        onCurve = (y_squared == mulmod(y, y, P));
        evaluate_y = y;
        x_on_curve = onCurve;
    }

    function getEvaluate() public view returns (uint256, bool) {
        return (evaluate_y, x_on_curve);
    }

    function ExpandPoint(uint256 Pin) public returns (uint256[2] memory Pout) {
        //Get x value (mask out sign bit)
        Pout[0] = Pin & (~ECSignMask);

        //Get y value
        bool onCurve;
        uint256 y;
        (y, onCurve) = EvaluateCurve(Pout[0]);

        //TODO: Find better failure case for point not on curve
        if (!onCurve) {
            Pout[0] = 0;
            Pout[1] = 0;
        } else {
            //Use Positive Y
            if ((Pin & ECSignMask) != 0) {
                if ((y & 0x1) == 0x1) {
                    Pout[1] = y;
                } else {
                    Pout[1] = P - y;
                }
            }
            //Use Negative Y
            else {
                if ((y & 0x1) == 0x1) {
                    Pout[1] = P - y;
                } else {
                    Pout[1] = y;
                }
            }
        }
    }

    //=====Ring Signature Functions=====
    function HashFunction(
        uint256 message,
        uint256[2] memory left,
        uint256[2] memory right
    ) public returns (uint256) {
        hash_function = (uint256(
            keccak256(abi.encodePacked(message, left[0], left[1], right[0], right[1]))
        ) % N);
        return hash_function;
    }

    function getHashFunction() public returns (uint256) {
        return hash_function;
    }

    //Return H = alt_bn128 evaluated at keccak256(p)
    function HashPoint(uint256[2] memory p) public returns (uint256[2] memory h) {
        bool onCurve;
        h[0] = uint256(keccak256(abi.encode(p[0]))) % N;

        while (!onCurve) {
            (h[1], onCurve) = EvaluateCurve(h[0]);
            h[0]++;
        }
        h[0]--;
        hash_point = h;
    }

    function getHashPoint() public returns (uint256[2] memory) {
        return hash_point;
    }

    function KeyImage(uint256 xk, uint256[2] memory Pk) public returns (uint256[2] memory Ix) {
        //Ix = xk * HashPoint(Pk)
        Ix = HashPoint(Pk);
        Ix = ecMul(Ix, xk);
    }

    function RingStartingSegment(
        uint256 message,
        uint256 alpha,
        uint256[2] memory P0
    ) public returns (uint256 c0) {
        //Memory Registers
        uint256[2] memory left;
        uint256[2] memory right;

        right = HashPoint(P0);
        right = ecMul(right, alpha);
        left = ecMul(G1, alpha);

        c0 = HashFunction(message, left, right);
    }

    //c0 needs to be c0*nonce
    function RingSegment(
        uint256 message,
        uint256 c0,
        uint256 s0,
        uint256[2] memory P0,
        uint256[2] memory Ix
    ) internal returns (uint256 c1) {
        //Memory Registers
        uint256[2] memory temp;
        uint256[2] memory left;
        uint256[2] memory right;

        //Deserialize Point
        (left[0], left[1]) = (P0[0], P0[1]);
        right = HashPoint(left);

        //Calculate left = c*nonce*P0 + s0*G1)
        left = ecMul(left, c0);
        temp = ecMul(G1, s0);
        left = ecAdd(left, temp);

        //Calculate right = s0*H(P0) + c*Ix
        right = ecMul(right, s0);
        temp = ecMul(Ix, c0);
        right = ecAdd(right, temp);

        c1 = HashFunction(message, left, right);
    }

    //SubMul = (u - c*xk) % N
    function SubMul(uint256 u, uint256 c, uint256 xk) public returns (uint256 s) {
        s = mulmod(c, xk, N);
        s = N - s;
        s = addmod(u, s, N);
    }

    //=== RingSignature ===
    //Inputs:
    //  message (RingMessage) - to be signed by the ring signature
    //  data (uint256[2*N+2]) - required data to form the signature where N is the number of Public Keys (ring size)
    //      data[0] - index from 0 to (N-1) specifying which Public Key has a known private key
    //      data[1] - corresponding private key for PublicKey[k]
    //      data[2   ... 2+(N-1)] - Random Numbers - total of N random numbers
    //      data[2+N ... 2*N+1  ] - Public Keys (compressed) - total of N Public Keys
    //      e.g. N=3; data = {k, PrivateKey_k, random0, random1, random2, PubKey0, PubKey1, PubKey2 }
    //
    //Outputs:
    //  signature (uint256[32]) - resulting signature
    //      signature[0] - keyimage for private key (compressed)
    //      signature[1] - c0 - start of ring signature - scaler for PublicKey[0]
    //      signature[2     ... 2+(N-1)] - s0...s[N-1], scalar for G1
    //      signature[2+N   ... 2*N+1  ] - Public Keys (compressed) - total of N Public Keys
    //      signature[2*N+2 ... 31     ] - Padding (0)
    //      e.g. N=3; signature = { Ik, c0, s0, s1, s2, PubKey0, PubKey1, PubKey2 }

    function RingSign(uint256 message, uint256[] memory data) public returns (uint256[32] memory) {
        //Check Array Lengths
        require(data.length >= 6, "Not enough signature value"); //Minimum size (2 PubKeys) = (2*2+2) = 6
        require(data.length <= 32, "Too much data"); //Max size - will only output 32 uint256's
        require((data.length % 2) == 0, "Uneven data length"); //data.length must be even
        uint256 ring_size = (data.length - 2) / 2;
        uint i;

        //Copy Random Numbers (most will become s-values) and Public Keys
        for (i = 2; i < data.length; i++) {
            ring_signature[i] = data[i];
        }

        //Memory Registers
        uint256[2] memory pubkey;
        uint256[2] memory keyimage;
        uint256 c;

        //Setup Indices
        i = (data[0] + 1) % ring_size;

        //Calculate Key Image
        pubkey = ExpandPoint(data[2 + ring_size + data[0]]); //Check whether correctly expanded
        keyimage = KeyImage(data[1], pubkey);
        ring_signature[0] = CompressPoint(keyimage);

        //Calculate Starting c = hash( message, u*G1, u*HashPoint(Pk) )
        c = RingStartingSegment(message, data[2 + data[0]], pubkey);
        if (i == 0) {
            ring_signature[1] = c;
        }

        for (; i != data[0]; ) {
            //Deserialize Point and calculate next Ring Segment
            pubkey = ExpandPoint(data[2 + ring_size + i]);

            c = RingSegment(message, c, data[2 + i], pubkey, keyimage);

            //Increment Counters
            i = i + 1;

            // Roll counters over
            if (i == ring_size) {
                i = 0;
                ring_signature[1] = c;
            }
        }
        //Calculate s s.t. alpha*G1 = c1*P1 + s1*G1 = (c1*x1 + s1) * G1
        //s = alpha - c1*x1*nonce
        ring_signature[2 + data[0]] = SubMul(data[2 + data[0]], c, data[1]);
        return ring_signature;
    }

    function getSignature() public view returns (uint[32] memory) {
        return ring_signature;
    }

    //=== RingVerify ===
    //Inputs:
    //  message (RingMessage) - signed by the ring signature
    //  signature (uint256[2*N+2]) - ring signature
    //      signature[0] - keyimage for private key (compressed)
    //      signature[1] - c0 - start of ring signature - scaler for PublicKey[0]
    //      signature[2     ... 2+(N-1)] - s0...s[N-1], scalar for G1
    //      signature[2+N   ... 2*N+1  ] - Public Keys (compressed) - total of N Public Keys
    //      e.g. N=3; signature = { Ik, c0, s0, s1, s2, PubKey0, PubKey1, PubKey2 }
    //Outputs:
    //  success (bool) - true/false indicating if signature is valid on message
    function RingVerify(uint256 message, uint256[] memory signature) public returns (bool success) {
        //Check Array Lengths
        require(signature.length >= 6, "More mix-in keys needed"); //Minimum size (2 PubKeys) = (2*2+2) = 6
        require(signature.length % 2 == 0, "Data length even"); //data.length must be even

        //Memory Registers
        uint256[2] memory pubkey;
        uint256[2] memory keyimage;
        uint256 c = signature[1];

        //Expand Key Image
        keyimage = ExpandPoint(signature[0]);

        //Verify Ring
        uint256 ring_size = (signature.length - 2) / 2;
        for (uint i = 0; i < ring_size; i++) {
            //Deserialize Point and calculate next Ring Segment
            pubkey = ExpandPoint(signature[2 + ring_size + i]);
            c = RingSegment(message, c, signature[2 + i], pubkey, keyimage);
        }

        success = (c == signature[1]);
    }
}
