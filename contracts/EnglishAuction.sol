// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint nftId
    )external;
}

contract EnglishAuction {
    event Start();
    event Bid(address sender,uint amount);

    IERC721 public immutable nft;
    uint public immutable nftId;

    address payable public immutable seller;
    uint32 public endAt;
    bool public started;
    bool public ended;

    address public biggestBidder;
    uint public biggestBid;
    mapping (address => uint) bids;

    constructor(
        address _nft,
        uint _nftId,
        uint _startBid
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        biggestBid = _startBid;
    }

    function start() external {
        require(msg.sender == seller ,"not seller");
        require(!started, "already started");

        started = true;
        endAt = uint32(block.timestamp + 60);
        nft.transferFrom(seller,address(this),nftId);

        emit Start();
    }

    function bid()external payable {
        require(started, "not started");
        require(block.timestamp < endAt,"already ended");
        require(msg.value >= biggestBid,"value < biggestBid");

        if (biggestBidder != address(0)){
            bids[biggestBidder] += biggestBid;
        }

        biggestBidder = msg.sender;
        biggestBid = msg.value;
        emit Bid(msg.sender,msg.value);
    }
}