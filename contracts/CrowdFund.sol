// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface IERC20 {
//     function transfer(address,uint256)external returns (bool);
//     function transferFrom(address,address,uint256)external returns (bool);
// }

contract CrowdFund {
    event Lanch(uint id, address indexed creator, uint goal, uint startAt, uint endAt);
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    //结构体用于存储每个众筹活动的信息，包括发起者、目标金额、已承诺金额、开始和结束时间以及是否已提取资金
    struct Compaign{
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }

    //定义了合约将使用的ERC20代币地址
    IERC20 public immutable token;
    //用于记录众筹活动的数量
    uint public count;

    //存储众筹活动的详细信息
    mapping (uint => Compaign) public compaigns;
    //记录每个用户在每个活动中承诺的金额
    mapping (uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    //创建新活动，检查时间有效性，初始化活动数据并发出Lanch事件
    function lanch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    )external{
        require(_startAt >= block.timestamp, "startAt < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 90 days, "end at > max duation");

        count += 1;
        compaigns[count] = Compaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed : false
        });

        emit Lanch(count, msg.sender, _goal, _startAt, _endAt);
    }

    //允许活动发起者在活动开始前取消活动，确保活动信息被删除
    function cancel(uint _id)external {
        Compaign memory compaign = compaigns[_id];

        require(msg.sender == compaign.creator, "not creator");
        require(block.timestamp < compaign.startAt, "started");

        delete compaigns[_id];

        emit Cancel(_id); 
    }

    //用户在活动期间承诺资金，更新承诺金额，转移代币到合约并发出Pledge事件
    function pledge(uint _id, uint _amount)external {
        Compaign storage compaign = compaigns[_id];
        require(block.timestamp >= compaign.startAt, "not started");
        require(block.timestamp <= compaign.endAt, "ended");

        compaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount); 

        emit Pledge(_id, msg.sender, _amount);
    }

    //用户在活动期间撤回部分承诺，更新承诺金额，转移代币返回用户并发出Unpledge事件。
    function unpledge(uint _id, uint _amount)external {
        Compaign storage compaign = compaigns[_id];
        require(block.timestamp <= compaign.endAt, "ended");

        compaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;

        token.transfer(msg.sender, _amount);
        emit Unpledge(_id, msg.sender, _amount);
    }

    //发起者在活动结束后提取资金，确保目标金额已达到，并发出Claim事件
    function claim(uint _id)external {
        Compaign storage compaign = compaigns[_id];
        require(msg.sender == compaign.creator, "not creator");
        require(block.timestamp > compaign.endAt, "not ended");
        require(compaign.pledged >= compaign.goal, "pledged < goal");
        require(compaign.claimed, "claimed");

        compaign.claimed = true;
        token.transfer(msg.sender, compaign.pledged);

        emit Claim(_id);

    }

    //当活动未达目标时，允许用户申请退款，确保金额正确并发出Refund事件
    function refund(uint _id)external {
        Compaign storage compaign = compaigns[_id];
        require(block.timestamp > compaign.endAt, "not ended");
        require(compaign.pledged < compaign.goal, "pledged < goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);

    }
}