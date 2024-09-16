// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

 contract SignatureVerification {
    function verify(address _signer, string memory _message, bytes memory _sig)external pure returns (bool){
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recover(ethSignedMessageHash,_sig) == _signer;
    }

    function getMessageHash(string memory _message) public pure returns (bytes32){
        return keccak256(abi.encodePacked(_message));
    }


    function getEthSignedMessageHash(bytes32  _messageHash) public pure returns (bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }


    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig) public pure returns (address){
        //椭圆曲线k1算法，v代表正负数
        (bytes32 r, bytes32 s, uint8 v)  = splitSignature(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
   }

   function splitSignature(bytes memory _sig) public pure returns(bytes32 r, bytes32 s, uint8 v){
        require(_sig.length == 65,"invalid signature length");

        //内联汇编 memory layout
        assembly{
            r := mload(add(_sig,32))
            s := mload(add(_sig,64))
            v := byte(0, mload(add(_sig,96)))
        }
   } 


 }