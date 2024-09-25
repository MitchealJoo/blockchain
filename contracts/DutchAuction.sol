// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//IERC721 是 ERC721 代币标准的接口，用于定义代币的基本功能。
interface IERC721 {
    //这个函数允许从 _from 地址转移 nftId 对应的 NFT 到 _to 地址。这个函数在后面的合约中被调用以实现 NFT 的转移
    function transferFrom(
        address _from,
        address _to,
        uint nftId
    ) external;
}


//这个合约实现了一个基本的荷兰式拍卖，通过逐渐降低价格来吸引买家。
//合约中的每个组件都是为了确保安全性、透明性和有效性，允许用户在特定时间内以动态价格购买 NFT
contract DutchAuction {
    //拍卖的持续时间，设定为 7 天
    uint private constant DURATION = 7 days;

    //表示要拍卖的 NFT 合约实例，使用 IERC721 接口。
    IERC721 public immutable nft;
    //表示特定 NFT 的 ID
    uint public immutable nftId;

    //拍卖的卖家地址（合约创建者）
    address public immutable seller;
    //拍卖的起始价格
    uint public immutable startingPrice;

    //拍卖开始的时间戳
    uint public immutable startAt;
    //拍卖结束的时间戳
    uint public immutable expireAt;
    //每秒减少的价格
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

        //require 语句确保起始价格高于拍卖结束时的折扣总额。
        require(_startingPrice >= _discountRate*DURATION, "startingPrice < discount");

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    //计算当前价格。根据经过的时间和折扣率，返回当前的拍卖价格
    function getPrice()public view returns (uint){
        uint timeElapsed = block.timestamp - startAt;
        uint discount = discountRate*timeElapsed;
        return startingPrice - discount;

    }

    //允许用户购买 NFT。首先检查拍卖是否仍在进行
    function buy() external payable{
        require(block.timestamp < expireAt, "aution expired");

        //调用 getPrice 获取当前价格，并确保发送的以太币大于等于当前价格
        uint price = getPrice();
        require(msg.value >= price,"ETH < price");

        //调用 transferFrom 函数，将 NFT 从卖家转移到购买者
        nft.transferFrom(seller, msg.sender, nftId);
        uint reFund = msg.value - price;
        if (reFund > 0){
            //如果发送的以太币超过当前价格，计算退款金额并将其返回给购买者
            payable(msg.sender).transfer(reFund);
        }

    }

    
}