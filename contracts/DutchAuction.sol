// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint nftId
    ) external;
}

contract DutchAuction {
    uint private constant DURATION = 7 days;

    IERC721 public immutable nft;
    uint public immutable nftId;

    address public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startAt;
    uint public immutable expireAt;
    uint public immutable discountRate;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingPrice,
        uint _discountRate
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startAt = block.timestamp;
        expireAt = block.timestamp + DURATION;
        discountRate = _discountRate;

        require(_startingPrice >= _discountRate*DURATION, "startingPrice < discount");

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice()public view returns (uint){
        uint timeElapsed = block.timestamp - startAt;
        uint discount = discountRate*timeElapsed;
        return startingPrice - discount;

    }

    function buy() external payable{
        require(block.timestamp < expireAt, "aution expired");

        uint price = getPrice();
        require(msg.value >= price,"ETH < price");

        nft.transferFrom(seller, msg.sender, nftId);
        uint reFund = msg.value - price;
        if (reFund > 0){
            payable(msg.sender).transfer(reFund);
        }

    }

    
}