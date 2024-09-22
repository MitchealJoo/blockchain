// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MultiSigWallet{
    //当有人向钱包存款时触发，记录发送者地址和金额
    event Deposit(address indexed sender, uint amount);
    //提交新的交易时触发，记录交易ID
    event Submit( uint indexed txId);
    //当某个拥有者批准交易时触发，记录批准者地址和交易ID
    event Approve(address indexed owner, uint indexed txId);
    //当某个拥有者撤销批准时触发，记录撤销者地址和交易ID
    event Revoke(address indexed owner, uint indexed txId);
    //交易被执行时触发，记录交易ID
    event Execute(uint indexed txId);

    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    //存储所有者地址的数组
    address[] public owners;
    //映射存储地址是否为钱包拥有者的布尔值
    mapping(address => bool) public isOwner;
    //执行交易所需的批准数量
    uint public required;
    //存储所有交易的数组
    Transaction[] public transactions;
    //映射存储每笔交易是否获得批准的状态
    mapping(uint => mapping(address => bool)) public approved;

    
    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint _txId){
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint _txId){
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    //初始化拥有者和所需批准数，确保有效性（例如，地址不为空且唯一）
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, " owners require");
        require(
            _required > 0 && _required <= owners.length,
            "invalied required number "
        );
        
        for (uint i; i < _owners.length; i++){
            address owner =_owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    //接收以太币时触发，记录存款事件
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }


    //允许拥有者提交新交易，记录交易的目的地、金额和附加数据
    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({
            to:_to,
            value:_value,
            data:_data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    //允许拥有者批准某笔交易，更新批准状态并触发事件
    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId){
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    //私有函数，计算某笔交易获得的批准数
    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++){
            if(approved[_txId][owners[i]]){
                count += 1;
            }
        }
    }

    //执行已批准的交易，确保获得足够的批准，调用指定地址的函数，并处理成功与否
    function execute(uint _txId) external txExists(_txId) notExecuted(_txId){
        require(_getApprovalCount(_txId) >= required, "approvals < required");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );

        require(success, "tx failed");
        emit Execute(_txId);
    }

    //允许拥有者撤销之前的批准，更新状态并触发事件
    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId){
        require(approved[_txId][msg.sender], "tx not approved ");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

}