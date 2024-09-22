// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MultiSigWallet2 {
    //关键点：要加索引
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);

    address[] public owners;
    mapping (address => bool) public isOwner;
    mapping (uint =>mapping (address => bool)) public approval;
    uint public required;
    Transaction [] transactions;

    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyOwner(){
        require(isOwner[msg.sender],"not owner");
        _;
    }

    modifier txIdExist(uint txId){
        require(txId < transactions.length,"tx not exist");
        _;
    }

    modifier notApproved(uint txId){
        require(!approval[txId][msg.sender],"tx already approved");
        _;
    }

    modifier notExecuted(uint txId){
        require(!transactions[txId].executed,"tx already executed");
        _;
    }

    constructor(address[] memory _owners,uint _required){
        require(_owners.length > 0,"owners less than 1"); 
        require(
            _required > 0 && _required <= _owners.length,
            "required invalid"
        );

        for (uint i; i < _owners.length; i++) {
            address owner =_owners[i];
            require(owner!=address(0),"owner invalid");
            require(!isOwner[owner],"owner is unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external payable { 
        emit Deposit(msg.sender,msg.value);
    }

    function submit(address _to,uint _value,bytes calldata _data)external onlyOwner{
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    function approve(uint txId)external onlyOwner txIdExist(txId) notApproved(txId) notExecuted(txId) {
        approval[txId][msg.sender] = true;
        emit Approve(msg.sender,txId);
    }

    function getApprovalCount(uint txId)private view returns (uint count){
        for (uint i; i < owners.length; i++) {
            if(approval[txId][owners[i]]){
                count += 1;
            }
        }
    }


    function execute(uint txId)external  txIdExist(txId)  notExecuted(txId) {
         require(getApprovalCount(txId) >= required, "do not reach required");
         Transaction storage transaction = transactions[txId];
         transaction.executed = true;


         //关键点：call的调用
        (bool success,) = transaction.to.call{value:transaction.value}(
            transaction.data
         );

         //关键点：判断是否执行失败
         require(success,"execute fail");
         emit Execute(txId);
    }

    function revoke(uint txId)external onlyOwner txIdExist(txId)  notExecuted(txId) {
        //关键点：要判断被批准了
        require(approval[txId][msg.sender], "tx not approved");
        approval[txId][msg.sender] = false;
        emit Revoke(msg.sender, txId);
    }
    
}