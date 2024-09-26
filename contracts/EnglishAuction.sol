// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//定义了ERC721标准
interface IERC721 {
    //保了合约可以安全地转移卖家的NFT到拍卖合约中
    function transferFrom(
        address _from,
        address _to,
        uint nftId
    )external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender,uint amount);
    event Withdraw(address indexed bidder,uint amount);
    event End(address indexed highestBidder,uint highestBid);

    //存储ERC721合约的地址，确保合约可以调用其方法
    IERC721 public immutable nft;
    //表示参与拍卖的NFT的唯一ID
    uint public immutable nftId;

    //存储拍卖的发起者地址，确保只有他们可以启动拍卖
    address payable public immutable seller;
    //记录拍卖结束的时间，确保在这个时间后无法再进行出价
    uint32 public endAt;
    //表示拍卖是否已经开始，防止重复启动
    bool public started;
    //表示拍卖是否已经结束，防止重复结束
    bool public ended;

    //存储当前最高出价者的地址
    address public highestBidder;
    //储当前最高出价的金额
    uint public highestBid;
    //记录每个地址的出价金额，方便在拍卖结束后进行退还
    mapping (address => uint) bids;

    //初始化合约，设置NFT地址、ID和起始出价  immutable修饰符确保这些变量在部署后无法修改
    constructor(
        address _nft,
        uint _nftId,
        uint _startBid
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startBid;
    }

    function start() external {
        //只能由卖家调用，确保拍卖的合法性
        require(msg.sender == seller ,"not seller");
        require(!started, "already started");

        //设置started为true，记录拍卖结束时间并转移NFT至合约
        started = true;
        endAt = uint32(block.timestamp + 60);
        nft.transferFrom(seller,address(this),nftId);

        emit Start();
    }

    //允许用户出价，确保拍卖已开始且未结束，出价必须高于当前最高出价
    function bid()external payable {
        require(started, "not started");
        require(block.timestamp < endAt,"already ended");
        require(msg.value > highestBid,"value < highestBid");

        //如果有现有的最高出价者，则将其出价退还（存入bids映射中）
        if (highestBidder != address(0)){
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit Bid(msg.sender,msg.value);
    }

    //允许出价者在未获胜的情况下退还自己的出价
    function withdraw()external {
        //前提:调用者不能是当前的最高出价者
        require(msg.sender != highestBidder, "highest bidder cannot withdraw");
        uint bal = bids[msg.sender]; 
        //通过将其在bids中的金额设置为0，防止重入攻击
        bids[msg.sender] = 0;

        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    function end()external {
        //只能在拍卖结束后调用，确保流程的正确性
        require(started,"not started");
        require(!ended,"ended");
        require(block.timestamp >= endAt,"not ended");

        ended = true;
        //转移NFT到最高出价者，或如果没有出价，则返回给卖家
        if (highestBidder != address(0)){
            nft.transferFrom(address(this),highestBidder,nftId);
            seller.transfer(highestBid);
        }else {
            nft.transferFrom(address(this),seller,nftId);
        }

        emit End(highestBidder,highestBid);
    }
}