// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint nftId
    )external;
}

contract EnglishAuction1 {
    event Start();
    //一定加索引
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address highestBidder,uint highestBid);

    IERC721 immutable public nft;
    uint immutable public nftId;

    address payable immutable public seller;
    uint32 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    //加public
    mapping (address =>uint) public bids;

    constructor(
        address _nft,
        uint _nftId,
        uint startingBid
    ) {
        nft = IERC721(_nft);
        nftId =_nftId;
        seller = payable(msg.sender);
        //注意构造时添加起拍价
        highestBid = startingBid;
    }

    function start(uint endTimeSecond)external {
        require(msg.sender == seller,"not seller");
        require(!started,"auction started");

        started = true;
        endAt = uint32(block.timestamp + endTimeSecond);
        
        //seller
        nft.transferFrom(seller,address(this),nftId);
        emit Start();
    }

    function bid()external payable{
        require(started,"not start");
        //只能小于结束时间
        require(block.timestamp < endAt,"auction ended");
        require(msg.value > highestBid,"value < highestBid");

        if (highestBidder!=address(0)){
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw()external{
        require(msg.sender != highestBidder,"highestBidder cannot withdraw");
        
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender,bal);
    }

    function end()external {
        require(started,"not start");
        require(!ended, "ended");
        //截止时间到了才能结束
        require(block.timestamp >= endAt, "not ended");

        //结束掉
        ended = true;

        if (highestBidder != address(0)){
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        }else {
            nft.transferFrom(address(this),seller,nftId);
        }

        emit End(highestBidder,highestBid);
    }


}

