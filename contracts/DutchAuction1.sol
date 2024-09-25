// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint nftId
    ) external;
}

contract DutchAuction1 {
    uint private constant DURATION = 7 days;

    address public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startAt;
    uint public immutable expiretAt;
    uint public immutable discountRate;

    IERC721 public immutable nft;
    uint public immutable nftId;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingPrice,
        uint _discountRate
    ) {
        //msg.sender必须加payable，否则无法接收以太币
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startAt = block.timestamp;
        expiretAt = block.timestamp + DURATION;
        discountRate = _discountRate;

        require(_startingPrice >= _discountRate*DURATION, "_startingPrice < discount");

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice()public view returns (uint){
        uint timeElapse = block.timestamp - startAt;
        uint discount = discountRate*timeElapse;
        return startingPrice - discount;
    }

    function buy() external payable{
        require(block.timestamp <= expiretAt, "auction expired");

        uint price = getPrice();
        require(msg.value >= price, "price > ETH");
        
        nft.transferFrom(seller, msg.sender, nftId);
        uint reFund = msg.value - price;
        if (reFund > 0){
            //注意退款的内置函数（合约向买方（即 msg.sender）转账）
            payable(msg.sender).transfer(reFund);
        }
    }
}