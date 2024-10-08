// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface IERC20 {
//     function transfer(address, uint)external returns (bool);
//     function transferFrom(address, address, uint)external returns (bool);
// }


contract CrowdFund1 {
    event Lanch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Cancel(uint id);
    event Pledged(uint indexed id, address indexed caller, uint amount);
    event UnPledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Compaign{
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }

    uint public count;
    IERC20 public immutable token;

    mapping (uint =>Compaign)public compaigns;
    mapping (uint =>mapping(address=>uint)) public pledgedAmount;


    constructor(address _token) {
        token = IERC20(_token);
    }

    function lanch(uint _goal, uint32 _startAt, uint32 _endAt)external{
        require(_startAt >= block.timestamp,"startAt < now");
        require(_startAt < _endAt, "endAt > endAt");
        require(_endAt <= block.timestamp + 90 days, "endAt > max duation");

        count += 1;
         
        compaigns[count]  = Compaign({
            creator:msg.sender,
            goal:_goal,
            pledged:0,
            startAt:_startAt,
            endAt:_endAt,
            claimed:false
        });

        emit Lanch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint _id)external{
        Compaign memory compaign = compaigns[_id];

        require(msg.sender == compaign.creator, "not creator");
        require(block.timestamp < compaign.startAt);

        delete compaigns[_id];
        emit Cancel(_id);
    }

    function pledge(uint _id, uint _amount)external{
        Compaign storage compaign = compaigns[_id];
        require(block.timestamp > compaign.startAt,"not start");
        require(block.timestamp < compaign.endAt, "ended");

        compaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        
        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledged(_id, msg.sender, _amount);
    }

    function unPledge(uint _id, uint _amount)external{
        Compaign storage compaign = compaigns[_id];
        require(block.timestamp < compaign.endAt, "ended");

        compaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;

        token.transfer(msg.sender,_amount);
        emit UnPledge(_id, msg.sender, _amount);
    }


    function claim(uint _id)external{
        Compaign storage compaign = compaigns[_id];
        require(msg.sender == compaign.creator, "not creator");
        require(block.timestamp > compaign.endAt, "not ended");
        require(compaign.pledged >= compaign.goal, "pledged < goal");
        require(compaign.claimed, "claimed");

        compaign.claimed = true;
        token.transfer(msg.sender, compaign.pledged); 
        emit Claim(_id);
    }

    function refund(uint _id)external{
        Compaign storage compaign = compaigns[_id];
        require(block.timestamp > compaign.endAt, "not ended");
        require(compaign.pledged < compaign.goal, "pledged >= goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }
}