// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract DeployWithCreate2 {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

contract Create2Factory {
    event Deploy(address addr);

    //_salt 是一个随机数，用于计算合约地址。它允许同样的合约代码在不同的 salt 下部署到不同的地址。
    function deploy(uint _salt)external {
        //msg.sender 被传递给 DeployWithCreate2 的构造函数，设置为新合约的 owner。
        DeployWithCreate2 _contract = new DeployWithCreate2{
            salt:bytes32(_salt)
        }(msg.sender);

        emit Deploy(address(_contract));
    }

    //getAddress 函数通过给定的合约字节码和 salt，计算使用 CREATE2 部署后合约的地址，而无需实际部署合约
    function getAddress(bytes memory bytecode, uint _salt) public view returns(address){
        bytes32 hash = keccak256(
            abi.encodePacked(
                //0xff 是一个常量，用于标识 CREATE2 的计算过程
                //address(this) 是当前工厂合约的地址，即新合约将由该工厂合约部署
                //_salt 是作为部署合约时传入的数值，它允许同样的字节码在不同的 salt 下生成不同的地址
                //keccak256(bytecode) 是将合约的字节码哈希化，用于生成地址
                bytes1(0xff),address(this),_salt,keccak256(bytecode)   
            )
        );

        // 20/32 =0.625
        // 160/256 =0.625
        //哈希结果经过类型转换，生成一个 address 类型的结果，这是合约将部署的预期地址
        return address(uint160(uint256(hash)));
    }   

    //getBytecode 函数返回用于部署 DeployWithCreate2 合约的字节码
    function getBytecode(address _owner)public pure returns(bytes memory){
        //type(DeployWithCreate2).creationCode：这是 Solidity 提供的一种获取合约创建代码的方法，它返回 DeployWithCreate2 合约的字节码
        bytes memory bytecode = type(DeployWithCreate2).creationCode;
        //abi.encodePacked(bytecode, abi.encode(_owner))：将字节码和 _owner 的编码组合起来，形成最终部署时所需的完整字节码
        return abi.encodePacked(bytecode, abi.encode(_owner));
    }
//这个工厂合约允许：
//使用 CREATE2 部署一个带有指定 owner 的 DeployWithCreate2 合约。
//通过提供合约字节码和 salt，预测合约的部署地址，而不需要实际部署合约。

//CREATE2 的核心用途是在链上部署合约之前，预先确定合约地址，并保证相同的字节码和 salt 始终会生成相同的地址。
//这在去中心化应用中具有广泛的应用场景，比如确保地址的确定性，或在不同时间点使用相同地址部署合约